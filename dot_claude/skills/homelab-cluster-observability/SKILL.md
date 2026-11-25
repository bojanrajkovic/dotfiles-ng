---
name: homelab-cluster-observability
description: Use when reading metrics, logs, or traces from Bojan's homelab — Prometheus (PromQL), Loki (LogQL), Honeycomb and ClickStack traces, pod logs, Renovate job logs, and Alloy's own pipeline health. Triggers on "check the logs", "what does Grafana show", "look at metrics", "find the trace", "why did this alert fire", "is Honeycomb down", or any homelab observability lookup.
user-invocable: true
metadata:
  version: 2.0.0
---

# Homelab cluster observability

Reach for the MCP tools first. They're already signed in and reach the cluster directly. Fall back to
direct HTTP or `kubectl` only when a tool can't answer the question.

| Signal | First choice | Fallback |
|---|---|---|
| Metrics | Grafana MCP, `query_prometheus` (datasource UID `prometheus`) | Prometheus HTTP API |
| Logs | Grafana MCP, `query_loki_logs` (datasource UID `loki`) | Loki HTTP API, `kubectl logs` |
| Traces | Honeycomb MCP | ClickStack MCP (`clickstack`), or SQL on ClickHouse |
| Alerts | Grafana MCP, `alerting_rules_read` | the rule files in the homelab repo |

Every query here is read-only.

## Metrics: Prometheus

Use `query_prometheus` with datasource UID `prometheus`. Before writing a query, look up metric names
with `list_prometheus_metric_names` (pass a `regex`) and label values with
`list_prometheus_label_values`.

## Logs: Loki

Use `query_loki_logs` with datasource UID `loki`. Every stream has the same five index labels, so
build selectors from them:

- `source`: `kubernetes`, `journal`, `syslog`, `events` or `otlp`
- `service_name`, `namespace`, `container`, `host`

Everything else is structured metadata, which you filter after the selector:
`{service_name="order-up"} | level="error"`. `level` is always `debug`, `info`, `warn`, `error` or
`fatal`. `trace_id` is structured metadata too. Use it to find a log line's trace. The homelab repo's
`docs/runbooks/logging.md` has the full schema.

Keep the selector narrow, with a specific `service_name` or `namespace`, and the window short. A
query's cost grows with the bytes Loki scans. Line filters run after the scan, so they don't lower the
cost. For counts, use a metric query such as `count_over_time(...)` with `queryType: instant`.

For a pod that's running now, `kubectl logs` shows lines as the pod writes them, before Loki ingests
them: `kubectl --context default -n <ns> logs deploy/<name> -c <container> --since=20m`. Use Loki for
logs from earlier pods, or from several pods at once.

## Traces: Honeycomb, then ClickStack

Alloy samples traces once, then sends every trace it keeps to both Honeycomb and ClickStack. Use these
two stores, not the Grafana MCP's Tempo tools.

**Honeycomb** is the first choice. Its team is `coderinserepeat` and its environment is `production`.
setlist PR previews go to `preview`. Each service is its own dataset, named after its `service.name`.
Start with `list_spans` and `get_span_details`, which often answer the question without a query. Then
use `run_query` for aggregates and `get_trace` for one trace.

**ClickStack** has the same traces, kept for 60 days. Use it when Honeycomb is down. To check, look at
status.honeycomb.io, or at Alloy's `otelcol_exporter_send_failed_spans_total` for the Honeycomb
exporters. The `clickstack` MCP server is built into HyperDX, ClickStack's UI. HyperDX is at
<https://traces.services.coderinserepeat.com>, and only the LAN and tailnet can reach it.

For questions the MCP tools can't express, run SQL on ClickHouse directly:

```bash
kubectl --context default -n clickstack exec clickstack-clickhouse-clickhouse-0-0-0 -- clickhouse-client -q "
  SELECT SpanName, count(), quantile(0.95)(Duration) / 1e6 AS p95_ms
  FROM otel_traces
  WHERE ServiceName = 'dox' AND Timestamp > now() - INTERVAL 1 HOUR
  GROUP BY SpanName ORDER BY 2 DESC LIMIT 20"
```

`otel_traces` columns: `Timestamp`, `TraceId`, `SpanId`, `ParentSpanId` (empty on root spans),
`ServiceName`, `SpanName`, `SpanKind`, `Duration` (nanoseconds), `StatusCode`, `SpanAttributes` and
`ResourceAttributes` (both `Map(String, String)`, read with `SpanAttributes['http.route']`).

Alloy tail-samples some routes and sets a `SampleRate` attribute on each root span it keeps.
Honeycomb's and HyperDX's charts weight counts by that rate. A raw SQL `count()` ignores the rate, so
sum `toUInt64OrDefault(SpanAttributes['SampleRate'], toUInt64(1))` instead when counting. The default
must be a `UInt64`, so a bare `1` fails.

## Alerts

`alerting_rules_read` lists the rules and their state. The rules themselves live in git, next to the
service they watch: `gitops/**/alerts/*.yaml` in the homelab repo. Routing is in
`gitops/infrastructure/kube-prometheus/alerts/contact-points.yaml`, and
`docs/runbooks/grafana-alerting.md` explains how a rule becomes a page.

## Is telemetry arriving at all?

When a service's data looks missing, check Alloy before blaming the service. Alloy exports metrics
about its own pipeline to Prometheus:

- `otelcol_receiver_accepted_spans_total` and `otelcol_receiver_accepted_log_records_total`: the spans
  and log records Alloy received.
- `otelcol_exporter_sent_spans_total` and `otelcol_exporter_send_failed_spans_total`, by
  `component_id`: what each exporter delivered. Honeycomb exporters are named
  `otelcol.exporter.otlphttp.honeycomb_<service>`, and ClickStack's is
  `otelcol.exporter.otlphttp.clickstack`.

The Telemetry Pipeline dashboard, in the Observability folder, charts all of this. To read Alloy's own
logs, run `kubectl --context default -n alloy logs ds/alloy -c alloy --since=15m | grep -i error`.

## Renovate runs

Renovate's logs are in three places:

- **Loki** has the info, warn and error lines, with `repo`, `job_id`, `result`, `exit_code` and
  `branch` as structured metadata:
  `{service_name="renovate"} | repo="bojanrajkovic/order-up" | level=~"warn|error"`. Each job ends
  with a `Repository finished` line, whose `exit_code` is non-zero when the job failed.
- **Debug logs** are on the PVC, one file per job, kept 30 days:
  `kubectl --context default -n renovate exec deploy/renovate -- ls /tmp/renovate/job-logs/<owner>/<repo>/`,
  then `cat` the newest file.
- **Traces** are in Honeycomb's `renovate` dataset.

To queue a run or list jobs through the server API, see the homelab repo's `docs/runbooks/renovate.md`.

## Direct HTTP fallback

Tailscale routes the cluster's Service CIDR, so this machine can reach a ClusterIP directly.
ClusterIPs change, so look them up every time:

```bash
clusterip() { kubectl --context default -n "$1" get svc "$2" -o jsonpath='{.spec.clusterIP}'; }
PROM="$(clusterip kube-prometheus kube-prometheus-kube-prome-prometheus):9090"
LOKI="$(clusterip loki loki):3100"

curl -s -G "http://$PROM/api/v1/query" --data-urlencode 'query=up{namespace="dox"}' | jq '.data.result'

# Loki expects timestamps in nanoseconds.
END=$(date +%s)000000000; START=$(( $(date +%s) - 1800 ))000000000
curl -s -G "http://$LOKI/loki/api/v1/query_range" \
  --data-urlencode 'query={namespace="dox"} | level="error"' \
  --data-urlencode "start=$START" --data-urlencode "end=$END" --data-urlencode 'limit=100' \
  | jq -r '.data.result[].values[][1]'
```

If a Service was renamed, find the new name with
`kubectl --context default get svc -A | grep -iE 'prometheus|loki|clickstack'`.
