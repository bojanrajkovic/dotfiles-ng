---
name: codex-review-plan
description: Use when reviewing an implementation plan or design plan with Codex before exiting plan mode or starting execution — covers the canonical `codex exec` invocation pattern (mktemp temp dir, stdin-piped prompt, read-only sandbox, xhigh reasoning), 5-section prompt structure, executor-context filter, and structured output triage. Triggers on "review the plan with Codex", "Codex review", or after writing a plan file to `~/.claude/plans/` for any non-trivial multi-step work.
---

# Codex Review of Plans

## Overview

Send a written plan to Codex (`mise exec npm:@openai/codex -- codex exec`) for an opinionated, structurally-rigorous review before execution. Codex with `xhigh` reasoning reads the plan, reads the cited files, and returns a tiered review: Blockers / Important concerns / Minor nits / Strengths / Unresolved questions. Treat blockers as required edits before `ExitPlanMode`; fold important concerns in unless there's a specific reason to defer.

This is the second-pair-of-eyes step that catches what in-cluster planning passes (Plan-agent, Explore subagents) miss — typically API contracts, framework footguns, accessibility regressions, and cross-section consistency gaps.

## When to Use

**Use when:**
- A plan has been written to disk (typically `~/.claude/plans/<slug>.md`) and is about to be exited via `ExitPlanMode`.
- Pre-implementation: reviewing a design plan that locks architecture before implementation planning.
- Pre-execution: reviewing an implementation plan that names files, signatures, and verification gates.
- Pre-merge: reviewing completed work against a plan (PR review). Use the dimensions in the "PR review variant" section below.

**Don't use for:**
- Single-file trivial edits where the "plan" is two sentences in chat.
- Plans that haven't been written to disk yet — write the plan first; the review reads the file.
- Plans whose ground-truth context isn't on disk (Codex can't review what it can't read).

## Prerequisites — verify once per machine

Codex is invoked via mise's npm shim. Two things must be true:

1. `mise exec npm:@openai/codex -- codex --version` resolves. If it errors, install it (`mise use -g npm:@openai/codex@latest` or per the user's mise config).
2. `~/.codex/config.toml` contains `model_reasoning_effort = "xhigh"`. **There is no CLI flag for this** — it is a config-file-only setting. If absent, the review will run at default reasoning and miss the depth that justifies the wait.

```bash
grep model_reasoning_effort ~/.codex/config.toml
# Expected: model_reasoning_effort = "xhigh"
```

If neither prerequisite holds, surface the gap to the user before proceeding — don't silently downgrade to a weaker review.

## Invocation Pattern

```bash
# 1. Create a UNIQUE per-review temp directory. NEVER hardcode `/tmp/codex-review/` —
#    it collides across sessions and stale artifacts get reused silently.
REVIEW_DIR=$(mktemp -d "/tmp/codex-plan-review-XXXXXX")
echo "$REVIEW_DIR"   # echo so the path is visible after the background run completes

# 2. Use the Write tool to place the prompt at "$REVIEW_DIR/prompt.md".
#    Do NOT inline as a heredoc in argv — heredoc-via-$() gets mangled through
#    mise exec → codex arg parsing.

# 3. Run codex with the prompt piped via stdin; outputs go to $REVIEW_DIR.
cat "$REVIEW_DIR/prompt.md" | mise exec npm:@openai/codex -- codex exec \
  --sandbox read-only \
  --color never \
  --output-last-message "$REVIEW_DIR/output.md" \
  - > "$REVIEW_DIR/codex.log" 2>&1
```

**Run with `run_in_background: true`** in the Bash tool — review takes 3–10 minutes at `xhigh`. Then `ScheduleWakeup` at ~270s (cache-warm) or use the background completion notification.

### Why each flag

- **`mktemp -d`** — unique per-review dir; prevents stale-file collisions. Session-scoped paths like `/tmp/codex-review-${SESSION_ID}` are an acceptable alternative when the session ID is ergonomic to thread through.
- **Write prompt to file, pipe via stdin (`-`)** — the `-` tells codex to read prompt from stdin. Avoids argv mangling through mise exec. Note: stdin carries the *prompt*; the *plan being reviewed* is referenced by absolute path inside the prompt body (under "Primary artifact"), and Codex reads it from its read-only sandbox at runtime.
- **`--sandbox read-only`** — codex reads files but cannot write. Reviewing, not authoring.
- **`--color never`** — strips ANSI codes from the log so you can grep it cleanly.
- **`--output-last-message FILE`** — captures the final structured review for direct reading. Without it you'd have to parse the log.
- **`> $REVIEW_DIR/codex.log 2>&1`** — capture stdout + stderr to disk. Diagnose hangs/errors after the fact. **Do NOT pipe through `| tail`** — argv mangling again, and the user has a feedback memory specifically against reflexive `tail`.

## Prompt Structure (5 sections + anti-patterns)

The prompt file (`$REVIEW_DIR/prompt.md`) follows this structure. Adapt scrutiny dimensions to the plan type (design vs. implementation vs. PR).

### 1. Role and context (1–2 paragraphs)

- What project, what stack, what artifact is being reviewed, where it sits in the overall sequence.
- **Executor context (required)** — state that the plan executor is an AI agent (Claude Code) with access to `CLAUDE.md`, feedback memories under `~/.claude/projects/*/memory/feedback_*.md`, and agent tooling (subagent dispatches, `project-claude-librarian`, etc.). Codex defaults to assuming a zero-context human and will otherwise flag agent-resolvable references as "unavailable" — those are false positives. Excerpt:

  > The plan executor is an AI coding agent (Claude Code) with access to project `CLAUDE.md` files, per-project feedback memories under `~/.claude/projects/*/memory/feedback_*.md`, and agent tooling (subagent dispatch, `project-claude-librarian`). Do NOT flag references to these resources as "unavailable" — the executor resolves them at runtime.

- **Ground truth statement** — "The [design plan / upstream ideation / etc.] is the ground truth. Read it first, then read the code."

### 2. Review dimensions (5–6 categories)

Pick the variant matching the artifact:

**Design plan / Implementation plan (pre-execution):**
1. **Architectural best practices** — component boundaries, state management, separation of concerns, testability, scalability.
2. **UX best practices and pitfalls** — real-time UX, animation correctness, accessibility (WCAG/ARIA), keyboard nav, screen-reader behavior, reduced-motion, empty/loading/error states, color-only information.
3. **Design internal consistency** — contradictions between sections, AC coverage gaps, phase ordering, unstated dependencies.
4. **Guideline conformance** — project-specific guidelines (`.ed3d/`, `.impeccable.md`, `CLAUDE.md`, `CONTRIBUTING.md`).
5. **Alignment with upstream ideation** — does the plan honor or intentionally diverge from prior decisions in ideation/spec docs.

**PR review (pre-merge variant):**
1. **Plan fidelity** — does the code match each locked decision in the plan?
2. **Code correctness** — async patterns, error propagation, types, API usage, transaction semantics.
3. **Test quality** — do tests verify what they claim? Are timing budgets realistic? AC coverage gaps?
4. **Phase boundary discipline** — no next-phase work accidentally pulled forward?
5. **Operational correctness** — shutdown, reconnect, fail-fast, metrics, deploy conditionals.
6. **Codebase alignment** — do new patterns follow or diverge from conventions elsewhere?

### 3. Files to read (categorized)

Codex won't read anything you don't name. Categorize:

- **Primary artifact** — the plan / PR diff itself. Read first.
- **Prior plans in the series** — for convention alignment (e.g., `~/.claude/plans/<earlier-slug>.md`).
- **Pre-code ideation/spec docs** — the upstream decisions the plan should honor.
- **Project guidelines** — every guideline file the plan must conform to (root `CLAUDE.md`, domain-level `CLAUDE.md` files, `.impeccable.md`, `CONTRIBUTING.md`).
- **Architecture docs** — `docs/architecture/*.md` for context on what exists.
- **Current codebase** — specific source files the plan modifies or depends on. Name them with file paths.

### 4. Specific scrutiny points (10–15 bulleted items)

This is where the review earns its keep. Generic "review for quality" produces generic output. Each point should name the specific mechanism, section, or AC it targets:

- "The plan uses pattern X — is this correct for framework Y? What hazards exist under condition Z?"
- "AC 4.2 says T — does the proposed implementation actually verify T, or only proxy?"
- "Sort uses `localeCompare` on ISO-8601 — is that the right tool here?"
- "Is the deferral of feature F a risky one that will be painful to retrofit?"
- "Guideline N says Y — does the plan conform? Cite the section."

Vagueness is the failure mode. "Review for accessibility" → poor output. "The plan adds a custom focus ring to `<button class='math-toggle'>`; does it preserve `:focus-visible` semantics under keyboard navigation, and does the ring meet WCAG 1.4.11 contrast at the chosen color?" → useful output.

### 5. Output format (mandatory, structured)

```
# [Feature] Plan Review

## Executive Summary
One paragraph: overall assessment, top 3 concerns, recommendation
(merge as-is / minor revisions / major revisions).

## Blockers (must fix before [implementation/merge])
Each: **Title**, section/AC/file:line reference, concrete fix.

## Important concerns (should fix, not a hard blocker)
Same format.

## Minor issues / nits
Same format.

## Strengths worth preserving

## Unresolved questions

## Guideline conformance checklist
For each project guideline principle: PASS / PARTIAL / FAIL + one-line justification.

## Alignment with upstream ideation
For each upstream decision: honored / intentionally diverged (justified) / accidentally diverged.
```

### Anti-patterns to forbid in the prompt

```
## What NOT to do
- Do not re-design. You are reviewing, not authoring.
- Do not restate sections of the plan or code.
- Do not hedge with "consider maybe…" — make concrete calls.
- Do not flag references to feedback_*.md, CLAUDE.md/AGENTS.md, or agent tooling as unavailable.
- Do not suggest future-phase work unless it creates a present-phase correctness problem.
- Do not flag formatting unless it obscures meaning.
- Be opinionated.
```

The "Be opinionated" line is load-bearing. Without it, Codex hedges. With it, Codex calls things wrong by name — which forces either a fix or an explicit overrule with rationale.

## Background and wakeup pattern

```
1. Compose prompt → Write to $REVIEW_DIR/prompt.md
2. Bash run with run_in_background: true, command = the codex exec invocation
3. Tell user: "Codex review running in background; will wake at ~270s to check"
4. ScheduleWakeup(delaySeconds: 270, reason: "checking codex review", prompt: <self>)
5. On wake: ls $REVIEW_DIR/output.md → if present, read it. If not, check $REVIEW_DIR/codex.log for hangs.
6. If still running, ScheduleWakeup again (270s)
7. When complete: read output.md, present blockers/important/minor to user
```

270s keeps the prompt cache warm (5-min TTL). 1200s is fine if you're confident the review takes longer; never pick exactly 300s.

## Triaging the output

Codex returns a tiered review. Process top-down:

1. **Blockers — fold every one into the plan** via `Edit` before exiting plan mode. If you disagree with a blocker, raise it to the user with reasoning before overruling. Don't silently dismiss.
2. **Important concerns — fold most in.** Defer only with an explicit reason ("this is out of scope for §X; tracked for §Y"). Don't accumulate "we'll address it later" debt.
3. **Minor nits — selectively apply.** Worth doing if cheap; skip if cosmetic. Bias toward applying.
4. **Strengths — preserved by default;** no action needed.
5. **Unresolved questions — surface to user.** These are the genuine "needs human decision" items.

### Filter false positives

Codex assumes a zero-context human executor. Findings that flag agent-resolvable resources as "unavailable" are false positives:

- "References `feedback_no_split_ts_test_files.md` but provides no path / file is missing" → false positive; the AI executor resolves this at runtime.
- "Dispatches `project-claude-librarian` agent but the agent isn't documented" → false positive; agent tooling is available.
- "Cites `CLAUDE.md` rules without quoting them" → false positive if the executor reads CLAUDE.md.

**Real findings** target technical correctness: compile errors, invalid commands, contradictory instructions, framework misuse, accessibility regressions. Keep those regardless of executor.

The executor-context section in the prompt (Section 1) is what reduces these false positives in the first place — but they still leak through. Filter at triage time.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Heredoc-inline the prompt as `codex exec "$(cat <<EOF...)"` | Write prompt to file; pipe via stdin with `-` |
| Pipe codex output through `| tail` | Redirect stdout/stderr to a log file in `$REVIEW_DIR` |
| Skip `mktemp -d`, use `/tmp/codex-review/` | Stale files collide silently; always `mktemp -d` |
| Foreground-run codex | Takes 3–10 minutes; always `run_in_background: true` |
| Forget to verify `xhigh` config | Default reasoning produces shallow output; check `~/.codex/config.toml` first |
| Generic scrutiny points ("review for correctness") | Name the specific mechanism / section / AC |
| Skip executor-context section | Codex flags agent-resolvable refs as unavailable; filter at triage cost more |
| Ignore Codex blockers without reasoning | At minimum surface the disagreement to the user before overruling |
| Use `--output-last-message` path that contains spaces | The codex CLI is finicky; keep `$REVIEW_DIR` simple (`/tmp/codex-plan-review-XXXXXX`) |

## Quick Reference

```bash
# One-time check
grep model_reasoning_effort ~/.codex/config.toml   # expect: "xhigh"

# Per-review
REVIEW_DIR=$(mktemp -d "/tmp/codex-plan-review-XXXXXX")
echo "$REVIEW_DIR"
# Write tool → $REVIEW_DIR/prompt.md
# Bash (run_in_background: true):
cat "$REVIEW_DIR/prompt.md" | mise exec npm:@openai/codex -- codex exec \
  --sandbox read-only --color never \
  --output-last-message "$REVIEW_DIR/output.md" \
  - > "$REVIEW_DIR/codex.log" 2>&1
# ScheduleWakeup(270, ...)
# On wake: read $REVIEW_DIR/output.md
```
