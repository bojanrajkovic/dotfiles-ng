---
name: ship-pr
description: Use when ready to ship a PR through Codex review and CI to admin-merge on a solo-contributor repo — encodes the loop of polling Codex review threads, addressing or escalating suggestions, waiting for Codex 👍 + green CI on the current HEAD, then admin-merging with squash. Triggers on "ship the PR", "land the PR", "merge after codex", "see this PR through".
---

# Ship PR After Codex

## Overview

For solo-contributor repos where admin-merge is appropriate, this skill encodes the end-game of a PR: trigger Codex with an explicit `@codex review` (the default — its auto-review on PR-open/push is slow and skips webhooks often enough that waiting on it stalls the loop), address or escalate its feedback, wait for CI to clear after the final commit, and admin-merge. The skill enforces ordering — never merge without a Codex 👍 on the CURRENT HEAD, never merge with red CI, never resolve a Codex thread before replying.

## When to Use

**Use when:**
- An open PR on a repo where you are the sole reviewer and admin-merge is the standard path.
- The PR is review-ready: code complete, tests added, description filled in, branch pushed.
- The PR is open (or you've just pushed a fix-up commit) and ready for a Codex review you'll trigger explicitly — see Step 2.

**Don't use when:**
- Multi-contributor repo where branch protection requires human review. Admin-merge bypasses that — explicitly out of scope.
- The PR has unresolved scope questions. Those need user judgment, not a polling loop.
- The repo doesn't have a Codex installation (the `chatgpt-codex-connector[bot]` app must be wired up — check by looking at any recently merged PR for its review).

## Prerequisites

- Authenticated `gh` CLI — used for everything: PR-state queries, the Monitor's polling shell, replies, thread resolution (GraphQL), and the admin-merge. No GitHub MCP plugin is needed (see Tool Preferences for why the CLI is the right call here).
- Admin permissions on the target repo (for the final `gh pr merge --admin`).
- Codex GitHub app installed on the repo (posts as `chatgpt-codex-connector[bot]`).

## The Loop

### Step 1 — Baseline

At skill entry, capture and remember:

- **PR number** — from the user, or inferred from the current branch via `gh pr view --json number,headRefOid,baseRefName`.
- **Owner / repo** — from `gh repo view --json owner,name` if not obvious from context.
- **Current HEAD SHA** — `git rev-parse HEAD` and verify it matches the PR's `headRefOid` (no local commits the remote doesn't have).
- **Latest Codex review ID** — `gh api repos/$OWNER/$REPO/pulls/$PR/reviews --paginate --jq '[.[] | select(.user.login=="chatgpt-codex-connector[bot]") | .id] | max'`. Anything older is "already known"; new reviews must have a strictly greater id. **`--paginate` is load-bearing**: without it the API returns only the first 30 review objects, so on a PR with a long review history the newest reviews are silently invisible — which reads as "Codex never responded" when it in fact did.
- **Latest Codex reaction timestamp on the PR** — `gh api repos/$OWNER/$REPO/issues/$PR/reactions` and find the most recent reaction from the bot.

Persist these in conversation. Each loop iteration compares against this baseline.

### Step 2 — Ensure Codex has been asked on the current HEAD

A 👍 from Codex attests ONLY to the specific commit SHA it reviewed. After ANY push to the branch, the previous 👍 is stale.

- **Default: post `@codex review` explicitly, once, on the current HEAD** via `gh api repos/$OWNER/$REPO/issues/$PR/comments -f body="@codex review"`. Codex's auto-review (on PR-open and on push) is unreliable — slow, and it drops webhooks often enough that waiting on it routinely stalls the loop — so trigger it yourself rather than betting on the auto-run. Post it after capturing the baseline (Step 1) on a freshly-opened PR, and again after each fix-up push. Then go to Step 3 and watch.
- **Once per HEAD, not per poll.** The nudge attaches to whatever HEAD is current when posted, so post it exactly once per commit you want reviewed — do NOT re-post while waiting. A redundant auto-run firing alongside your explicit one is harmless (the monitor takes the first review with `id > BASELINE_REVIEW`); re-posting on every poll is the actual mistake.

### Step 3 — Watch for Codex's response

Use `Monitor` (not `Bash` `run_in_background`) so the model is informed on each state transition and can triage per-event rather than waking only on terminal exit.

```bash
PR={pr_number}
OWNER={owner}
REPO={repo}
BASELINE_REVIEW={latest_known_codex_review_id_or_0}
while true; do
  thumbs=$(gh api "repos/$OWNER/$REPO/issues/$PR/reactions" --jq \
    '[.[] | select(.user.login=="chatgpt-codex-connector[bot]") | select(.content=="+1")] | length' \
    2>/dev/null || echo 0)
  new_review=$(gh api "repos/$OWNER/$REPO/pulls/$PR/reviews" --paginate --jq \
    '[.[] | select(.user.login=="chatgpt-codex-connector[bot]") | select(.id > '"$BASELINE_REVIEW"')] | .[0].id' \
    2>/dev/null)
  # Emit ONLY at the actionable break (a 👍 or a new review). Do NOT echo the
  # per-poll state: between "nothing yet" and the break the state never changes,
  # so an echo-on-change loop just fires ONE wasted notification per watch — the
  # baseline `thumbs=0 new_review=none` print that wakes the model for nothing.
  [ "$thumbs" -gt 0 ] && { echo "codex: thumbs-up on the current HEAD"; break; }
  [ -n "$new_review" ] && { echo "codex: new review $new_review landed"; break; }
  sleep 60
done
```

Wrap this in `Monitor` with `persistent: false`, `timeout_ms: 1800000` (30 min). On the exit event, inspect with `gh api`:

- `gh api repos/$OWNER/$REPO/pulls/$PR/reviews --paginate` — see if the new review is COMMENTED (has suggestions) or APPROVED (rare from Codex), and which `commit_id` it reviewed. (Every `…/reviews` query needs `--paginate` — page 1 is 30 objects.)
- `gh api repos/$OWNER/$REPO/pulls/$PR/reviews/$REVIEW_ID/comments` — read that review's line-level suggestions (`{path, line, body}`).

### Step 4 — Address Codex feedback

**Surface the review to the user FIRST, and wait for a go-ahead before applying anything.** When a new Codex review lands, post a one-line-per-finding summary (severity, file, claim, and your proposed triage) to the user *before* implementing anything — including findings you'd classify as clearly-correct. The user authored the PR; auto-applying and pushing leaves them discovering the changes after the fact. This is a hard stop, not a courtesy notice: do not fix-and-push, do not reply-and-resolve, until the user replies. The only exception is a finding the user has already pre-approved in this same conversation (e.g. "yes, apply anything obvious").

For each new line-level comment from Codex:

1. **Triage and propose, don't apply:**
   - **Clearly correct** → propose the fix (what you'd change, and why) and wait for the user's go-ahead before touching the diff.
   - **Scope-expanding** (touches files outside the current PR's diff, or proposes a refactor unrelated to the PR's stated goal) → escalate to the user with a one-paragraph summary. Don't quietly expand the diff.
   - **Intentional / wrong** → propose the reply explaining the reasoning (Codex sometimes flags pre-existing patterns the PR didn't introduce) and confirm with the user before posting it.

2. **Reply BEFORE resolving.** Reply in-thread with `gh api repos/$OWNER/$REPO/pulls/$PR/comments/$COMMENT_ID/replies -f body="…"` (the `$COMMENT_ID` is the review comment's REST `id` / GraphQL `databaseId`) to acknowledge the fix with the new commit SHA, or to record the decline. Resolving without a reply leaves Codex's comment as the only context if anyone revisits.

3. **Resolve only after the fix lands** on the remote. The REST review-comment payload does NOT expose the GraphQL thread node ID (needed to resolve) — fetch the thread ids, each thread's first-comment author, and the comment's `databaseId` (for the reply in step 2) via GraphQL:

   ```bash
   gh api graphql -f query='
   {
     repository(owner: "OWNER", name: "REPO") {
       pullRequest(number: PR) {
         reviewThreads(last: 50) {
           nodes {
             id
             isResolved
             comments(first: 1) { nodes { databaseId author { login } path } }
           }
         }
       }
     }
   }' --jq '.data.repository.pullRequest.reviewThreads.nodes[]
             | select(.isResolved == false)
             | select(.comments.nodes[0].author.login == "chatgpt-codex-connector")
             | "\(.id)\t\(.comments.nodes[0].databaseId)\t\(.comments.nodes[0].path)"'
   ```

   **Gotcha:** in GraphQL the bot's login is `chatgpt-codex-connector` (no `[bot]` suffix); in the REST API it's `chatgpt-codex-connector[bot]`. Filter accordingly or you'll get zero matches.

   Then resolve each thread with the GraphQL mutation (reply first!):

   ```bash
   gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "PRRT_kwDOxxx"}) { thread { isResolved } } }'
   ```

4. **Push the fix, re-trigger Codex (Step 2), and loop back to Step 3.** After the push lands on the remote, post `@codex review` again for the new HEAD — don't rely on the push's auto-review. The baseline review ID gets refreshed implicitly because we filter by `id > BASELINE_REVIEW`, and the previous review is now baseline.

### Step 5 — Wait for CI green after Codex 👍

Once Codex has 👍'd (no new line-level comments on the current HEAD), the PR is review-clean. Now wait for CI:

```bash
PR={pr_number}
HEAD={head_sha}
prev=""; prev_names=""
while true; do
  state=$(gh api "repos/$OWNER/$REPO/commits/$HEAD/check-runs" --jq \
    '[.check_runs[] | "\(.name):\(.status):\(.conclusion // "running")"] | sort | .[]' \
    2>/dev/null)
  names=$(printf '%s\n' "$state" | sed 's/:.*//' | sort -u)
  if [ "$state" != "$prev" ]; then
    printf '%s\n' "$state" | while read -r line; do [ -n "$line" ] && echo "ci: $line"; done
    prev=$state
  fi
  # Still running? keep waiting.
  if printf '%s\n' "$state" | grep -v ":completed:" >/dev/null; then
    prev_names=$names; sleep 60; continue
  fi
  # GUARD against the unregistered-check race: an empty list, or a check set that
  # changed since the last poll, means a required check may not have been CREATED
  # yet (right after a push the list briefly holds only the fast checks, e.g.
  # "Validate PR Title", before "Build & Test" registers). "All currently-listed
  # checks completed" is NOT "all checks completed" until the set is stable.
  # Only declare a verdict when the set is non-empty AND unchanged across two
  # consecutive polls AND all completed.
  if [ -z "$names" ] || [ "$names" != "$prev_names" ]; then
    prev_names=$names; sleep 60; continue
  fi
  if printf '%s\n' "$state" | grep -E ":completed:(failure|cancelled|timed_out|action_required)" >/dev/null; then
    echo "ci: FAIL"
  else
    echo "ci: ALL_GREEN"
  fi
  break
done
```

Wrap in `Monitor`. On `ci: FAIL` events, inspect the failing run with `gh api repos/$OWNER/$REPO/commits/$HEAD/check-runs`, pull failing logs with `gh run view <run-id> --log-failed`, fix, push, and restart at Step 2.

**If you know the required check name(s)** (e.g. `Build & Test`), prefer gating on them directly — wait until each named check is present AND `completed`, then read its conclusion — which is strictly more robust than the set-stability heuristic. The stability guard is the name-agnostic fallback.

### Step 6 — Admin-merge

With Codex 👍 attached to the current HEAD AND all required checks `completed:success` (or `completed:skipped` / `completed:neutral`) AND no new commits since the 👍:

```bash
gh pr merge {pr_number} --admin --squash --delete-branch
```

- **`--squash`** matches the typical solo-contributor convention — one PR → one main commit. Verify by checking `CONTRIBUTING.md` if uncertain; some repos prefer `--rebase` or `--merge`.
- **`--admin`** bypasses branch protection; required for solo repos that have protection rules but no second reviewer.
- **`--delete-branch`** cleans up the feature branch from the remote.

After merge:

```bash
git checkout {default_branch} && git pull
```

## Hard Guards

These conditions must NEVER be silently overridden. If any tripwires fire, stop and ask the user.

1. **No merge without a Codex 👍 on the current HEAD.** If a commit landed after the most recent 👍 reaction, the 👍 is stale — re-trigger and wait. Verify by comparing `git rev-parse HEAD` to the SHA Codex's review was on (visible in `get_reviews` as `commit_id`).

2. **No merge with any check at `status != completed` OR `conclusion in {failure, cancelled, timed_out, action_required}`.** `success`, `skipped`, `neutral` are passing; everything else blocks. `action_required` in particular is waiting for a human signal — admin-merge would bypass it.

3. **No silent scope expansion.** If Codex's suggestion touches files outside the PR's existing diff, escalate. The user authored the PR with a specific scope; Codex doesn't know that scope and may propose adjacent improvements.

4. **Reply to Codex BEFORE resolving the thread.** Without a reply, the only artifact left is Codex's comment — anyone revisiting loses the context of how it was addressed.

5. **Trigger Codex once per HEAD, never per poll.** Posting `@codex review` to drive the review is the default (Step 2), but post it exactly once per commit you want reviewed — re-posting while a review is in flight piles duplicate runs on the bot's queue and muddies the baseline. One explicit trigger per HEAD; then watch.

6. **No applying a Codex finding — fix, reply, or resolve — without the user's go-ahead first.** This holds even for findings you're confident are clearly correct. Post the triaged summary and wait; don't fix-and-push preemptively "to save a round trip." The one exception is a finding type the user has explicitly pre-approved earlier in the same conversation.

## Tool Preferences

- **Use `gh` for everything** — PR-state queries, replies, thread resolution, CI, and the admin-merge. Don't reach for the GitHub MCP here. It buys nothing over the CLI for this loop: the MCP is just another request/response API client, it can't stream CI results or new comments _into_ the session (the "message channels" that surface remote events live only in Claude Code on the Web, not in the MCP), and it isn't callable from the Monitor's polling shell anyway. So keep the loop uniformly `gh`-based — one tool, one auth, works in and out of the Monitor.
- **GraphQL:** `gh api graphql -f query='...'` for thread node IDs and any field the REST API doesn't surface (e.g., `reviewThreads.nodes[].id`, and the `resolveReviewThread` mutation).
- **Admin-merge:** `gh pr merge --admin` bypasses branch protection — required for solo repos that have protection rules but no second reviewer.
- **Mise-managed `gh` gotcha:** if `gh` is installed via mise (or another per-directory version manager), it can drop off `PATH` inside a `while … done` loop or `$(…)` subshell once a `cd` reshapes the env — you'll see `command not found: gh` even though it works at the top level. Use the absolute path (`g=$(which gh)`, then `"$g" api …`) inside loops, or run the calls as flat top-level commands.

## Common Mistakes

| Mistake | Why it bites | Fix |
|---|---|---|
| Polling Codex every 5 s | GitHub API rate limits and the model wakes for every tick. | 60 s intervals. Monitor docs spec ≥30 s for remote APIs. |
| Treating the original 👍 as still valid after a follow-up commit | The 👍 attests to a specific SHA; new commits invalidate it. | Re-trigger after every push; wait for a fresh 👍. |
| Resolving a Codex thread without replying first | Loses your acknowledgement context permanently. | Reply with the fix commit SHA, THEN resolve. |
| Treating `action_required` as green | Admin-merge would bypass a check that's deliberately waiting on a human. | Block; ask the user. |
| `gh pr merge` without `--admin` on a protected branch | The merge silently queues or fails. | `--admin` for solo repos with protection rules. |
| Replying via top-level comment when Codex commented on a line | The reply lands as a sibling top-level comment, not threaded under Codex's. | Reply via `gh api .../pulls/$PR/comments/$COMMENT_ID/replies -f body=…` with the Codex comment's id. |
| Auto-fixing a Codex suggestion that expands PR scope | Diff grows without user signoff; PR description no longer matches contents. | Escalate to user; ask whether to fold in or defer. |
| Auto-applying a "clearly correct" Codex finding without asking first | The user authored the PR and finds out about changes only after they're pushed — even a correct fix isn't yours to apply unilaterally. | Post the triaged summary and wait for a go-ahead before fixing, replying, or resolving anything. |
| Querying `…/pulls/$PR/reviews` without `--paginate` | Page 1 is 30 objects; a long review cycle pushes the newest reviews onto page 2 — they become invisible to the monitor AND to manual checks, which looks exactly like "Codex stalled". | `--paginate` on every reviews query (baseline, monitor loop, post-exit inspection). Same class of bug: `reviewThreads(first: 50)` in GraphQL — use `last: 50` so the newest threads are in the window. |
| Declaring CI green before the required check has registered | Right after a push the commit's check-runs list briefly holds only the fast checks (e.g. `Validate PR Title`); the slow one (`Build & Test`) hasn't been created yet. "All currently-listed checks completed" then reads as ALL_GREEN, and the monitor exits before the real CI even starts — so a run that later fails looks green. | Never treat a partial/empty check set as terminal. Require the check set to be non-empty AND unchanged across two consecutive polls before computing a verdict (Step 5 guard), or gate directly on the known required check name(s) being present-and-completed. |

## Skill Boundaries

- **In scope:** End-game shepherding of a code-complete PR through Codex + CI to admin-merge.
- **Out of scope:** Writing the PR, addressing complex review feedback that requires user judgment, multi-contributor approval workflows, handling Codex outages or non-response (>30 min).
- **Hand-off triggers:** Scope-expanding Codex suggestions, CI failures that require non-trivial fixes (>~15 LOC of new code), branch-protection violations, ambiguity about whether a thread is "addressed."

## State Machine Summary

```
[ baseline ] → [ post @codex review (once/HEAD) ] → [ Monitor: poll Codex events ]
                            ↓
            ┌─────────── new review ───────────┐
            ↓                                  ↓
   [ has suggestions? ]                  [ no, just 👍 ]
            ↓                                  ↓
   [ triage + post summary ]          [ Monitor: poll CI ]
            ↓                                  ↓
   [ WAIT for user go-ahead ]         ┌───── ALL_GREEN? ─────┐
            ↓                          ↓                      ↓
   [ fix/reply per user's call ]  [ FAIL ]              [ admin-merge ]
            ↓                          ↓                      ↓
   [ push fix + @codex review ]  [ fix + push + loop ]  [ checkout main; pull ]
            ↓
   (loop back to Monitor)
```
