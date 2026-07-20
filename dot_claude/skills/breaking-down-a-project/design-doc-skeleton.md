# The per-epic implementation-design spine (Phase 6, step 1)

Read this when you reach Phase 6 and are fleshing an epic's design. This is the artifact
written *before* an epic's code — the thing that makes the eventual PR obvious to write and
fast to review. It lives in the project wiki (one child per epic under the initiative hub),
**not** committed to the worktree. The ADR holds the *why*; this doc holds *what ships and how*.

```
> Status: <branch> · <PR link once open> · design-only until the WAIT gate clears.
> Build plan for <EPIC-ID> (#<parent>). The why + rejected alternatives live in <ADR-NNNN>.

## Context
One paragraph: what this epic delivers and where it sits in the initiative (which rung /
wave, what it unblocks). Link the parent epic and the ADR.

## Grounded context   (verify before you assert)
Every seam this change touches, pinned to file:line, each fact tagged (verified) or
(UNVERIFIED → must close before the design is done). Re-derive caller sets from the
registry, not from a doc-comment; unpack and read external deps' shipped .d.ts. The
biggest design risk is the unverified dependency — close it here.

## Design
The shape of the change. For each genuine fork: the 2–3 alternatives, the rejected ones,
and THE DISCRIMINATOR that chose between them (not just the winner). Show real type/callsite
sketches for the one consequential seam so the human decides on concrete artifacts.

## Decisions  (numbered)
1. <decision> — <one-line rationale>. (ADR-worthy? → file ADR-NNNN at decision time.)
2. ...

## Done
- [ ] The exit criteria. Pin when to STOP. Protect tests/docs as part of the deliverable.

## Out of scope
- <neighboring concern> → handed to <downstream epic #NNN>, not this PR.

## Implementation plan
The sub-issue order as a fixed sequence of atomic, gate-green commits, each mapped to a
sub-issue. Substrate commits before their consumers. Note where a settled design lets
several sub-issues collapse into one PR (still one atomic commit each).

## Risks  (lettered, each with a mitigation)
- A. <risk> → <mitigation / the test that enforces it>.
- B. ...

## References
The ADR, the audit row(s) this traces to, sibling epics' design docs, the initiative hub.
```

**Why the spine is load-bearing:** the **Grounded context** + **Design (with discriminator)**
sections are where the contentious naming/shape gets settled against a *document* instead of
against committed code. A reviewer of the resulting PR is checking a *blessed* design, not
discovering one — which is the whole reason the PRs review fast and don't churn.
