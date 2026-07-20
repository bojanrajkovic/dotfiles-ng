---
name: homelab-cluster-observability
description: Use when querying traces, metrics, or logs from Bojan's homelab k8s cluster — Tempo (TraceQL), Prometheus (PromQL), Loki (LogQL), and pod logs. Triggers on "query Tempo", "check the trace", "look at metrics/Prometheus", "grep the logs", "what does Grafana show", or any homelab observability lookup. Also for reading spike/deploy telemetry.
user-invocable: true
metadata:
  version: 1.0.0
---

# Homelab cluster observability

Query the homelab observability stack **directly**, without Grafana auth or `kubectl port-forward`. The cluster is the `default` kubectl context, and its ClusterIPs are routable from this machine over Tailscale — so an `http://<clusterIP>:<port>/...` curl just works.

## The one rule: discover endpoints every time

**ClusterIPs are NOT stable** — never hardcode them, and don't trust an IP from a previous session. Resolve the service's current ClusterIP at call time. Service *names/namespaces* are far more stable than IPs, so resolve by name:

```bash
# Resolve "<ns>/<svc>:<port>" → "<clusterIP>:<port>"
clusterip() { kubectl --context default -n "$1" get svc "$2" -o jsonpath='{.spec.clusterIP}'; }

TEMPO="$(clusterip tempo tempo):3200"
PROM="$(clusterip kube-prometheus kube-prometheus-kube-prome-prometheus):9090"
LOKI="$(clusterip loki loki):3100"
```

If a name has changed, find it — don't guess:

```bash
kubectl --context default get svc -A | grep -iE 'tempo|prometheus|loki|grafana'
```

Sanity-check reachability before a real query: `curl -s -m5 -o /dev/null -w '%{http_code}\n' "http://$TEMPO/api/echo"` (expect `200`).

## Tempo (traces) — port 3200

Search by TraceQL, then fetch the full trace by ID. Times are unix seconds; always pass `start`/`end` (default window is tiny).

```bash
END=$(date +%s); START=$((END-1800))   # last 30 min
# Search: returns matching traces (id + root span name), NOT child spans
curl -s -G "http://$TEMPO/api/search" \
  --data-urlencode 'q={ name =~ "paprika-widget:.*" }' \
  --data-urlencode "start=$START" --data-urlencode "end=$END" --data-urlencode 'limit=50' \
  | python3 -c 'import sys,json; [print(t["traceID"], t.get("rootTraceName")) for t in json.load(sys.stdin).get("traces",[])]'
```

The child spans (the interesting ones) live *inside* a trace — fetch it and flatten. This dumper prints each span's name, offset, duration, and the attributes worth seeing:

```bash
curl -s "http://$TEMPO/api/traces/<TRACE_ID>" | python3 -c '
import sys,json
d=json.load(sys.stdin)
def v(x):
    for k in ("stringValue","intValue","boolValue","doubleValue"):
        if k in x: return x[k]
    return x
spans=[]
for b in d.get("batches",[]):
    for ss in b.get("scopeSpans",[]):
        for s in ss.get("spans",[]):
            st=int(s.get("startTimeUnixNano",0)); en=int(s.get("endTimeUnixNano",0))
            at={a["key"]:v(a["value"]) for a in s.get("attributes",[])}
            spans.append((st,en,s.get("name",""),at))
spans.sort(); t0=spans[0][0] if spans else 0
for st,en,nm,at in spans:
    print(f"+{(st-t0)/1e6:8.1f}ms  {(en-st)/1e6:7.1f}ms  {nm}")
    for k,val in at.items():
        if k.startswith(("mcp","gen_ai","mcp_paprika","session")): print(f"            {k}={val}")
'
```

TraceQL quick reference: `{ name =~ "regex" }` (span name, RE2, unanchored), `{ resource.service.name = "mcp-paprika" }`, `{ span.<attr> = "x" }`, `{ name = "a" && resource.service.name = "b" }`. Intrinsic `name`/`duration`/`status` need no prefix; resource attrs take `resource.`, span attrs `span.`.

## Prometheus (metrics) — port 9090

```bash
# Instant query
curl -s -G "http://$PROM/api/v1/query" --data-urlencode 'query=up{namespace="mcp-paprika"}' \
  | python3 -c 'import sys,json; [print(r["metric"],r["value"]) for r in json.load(sys.stdin)["data"]["result"]]'

# Range query (step in seconds)
END=$(date +%s); START=$((END-3600))
curl -s -G "http://$PROM/api/v1/query_range" \
  --data-urlencode 'query=nodejs_eventloop_delay_max{service_name="mcp-paprika"}' \
  --data-urlencode "start=$START" --data-urlencode "end=$END" --data-urlencode 'step=60'
```

## Loki (logs) — port 3100

LogQL over the read API. Times are unix **nanoseconds** here (Loki quirk), so `$(date +%s)000000000`.

```bash
END=$(date +%s)000000000; START=$(( $(date +%s) - 1800 ))000000000
curl -s -G "http://$LOKI/loki/api/v1/query_range" \
  --data-urlencode 'query={namespace="mcp-paprika"} |= "record_widget_timing"' \
  --data-urlencode "start=$START" --data-urlencode "end=$END" --data-urlencode 'limit=100' \
  | python3 -c 'import sys,json; [print(ts,line) for s in json.load(sys.stdin)["data"]["result"] for ts,line in s["values"]]'
```

## Pod logs — the fast path

For a live pod, `kubectl logs` is simpler than Loki and has no ingest lag:

```bash
P=$(kubectl --context default -n mcp-paprika get pods --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
kubectl --context default -n mcp-paprika logs "$P" --since=20m | grep -iE 'pattern'
```

Loki wins for history (across restarts / deleted pods) and cross-pod queries; `kubectl logs` wins for the current pod, right now.

## Notes

- Everything is read-only — safe to run freely.
- Pino logs are JSON; pipe through `python3 -c 'import sys,json;...'` or `jq` to pull fields. Level codes: 30=info, 40=warn, 50=error.
- The MCP server runs in namespace `mcp-paprika` (container + deployment both named `mcp-paprika`); `service_name`/`namespace` label is `mcp-paprika` across all three backends.
