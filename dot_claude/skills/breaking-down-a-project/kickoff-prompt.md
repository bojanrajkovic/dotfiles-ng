# The per-epic kickoff prompt (Phase 6)

Read this when you reach Phase 6 of the `breaking-down-a-project` skill. Every epic ships
with the **same** prompt shape, pasted into a fresh session — the sameness is what lets you
hand an epic to a clean context (or to yourself a day later) and get a small, low-churn PR
without re-explaining the project. Generate the next epic's prompt by imitating the last one.

## Fill-in-the-blanks template

```
Let's start <EPIC-ID> (#<parent-issue>) on the <initiative> board — <one line: what it is>
— <why it's next on the DAG, e.g. "the next wave-0 root now that <prev epic> is done">.
Start with <#first-sub-issue> (<what it ships>); <#next-subs> build on it.

Grounding (read before proposing):
- <Outline/wiki design-doc URL for this epic — its canonical home>
- <the ADR it implements + the audit doc + sibling design docs>, by URL
- <the exact code seams / SDK or dependency surface to verify, by path/symbol>

Soft sub-issue order: <#a FIRST … then #b … then #c>
  (the order the GitHub blocked-by edges don't encode).

<EPIC-ID> has no implementation-design doc yet, so designing it is part of this. Follow the
planning process in CLAUDE.md: start from current main (git fetch + rebase); ground in the
docs and verify before you assert; pin "done" / out-of-scope; brainstorm the real
alternatives; attack your own design; and ask me clarifying questions.

Write the <EPIC-ID> implementation-design as a child doc under the <initiative> wiki parent
(spine: design-doc-skeleton.md). If a decision with real alternatives falls out, record it
as an ADR at decision time.

Show me the design and WAIT for my feedback before building.

Then implement <#first-sub-issue> first as its own PR off a fresh branch from current main;
<#next-subs> follow as separate PRs (collapse to one PR only if the settled design makes the
split arbitrary). Run /code-review on the final diff scaled to the change (low/medium
localized · high kernel-touching · max sweeping), and ship via /ship-pr. File any
out-of-scope discoveries as sub-issues parented to the right epic — the PR shouldn't close
the epic if they belong to it.
<The worktree already exists but needs rebasing on main / a fresh worktree off <base>.>
```

## The load-bearing parts — none optional

1. **Point at the design doc by canonical URL and list the exact grounding to read first.** Hand over the *real* URLs — a fresh session (or subagent) will fabricate plausible-but-wrong ones from memory if you don't.
2. **Invoke the project's planning process by reference, not by re-spelling it** — the seven-phase "design ONE change" loop lives in the project's planning doc / root `CLAUDE.md`; the kickoff just *names* it so the work inherits it.
3. **The explicit WAIT gate before code.** "Show me the design and wait for feedback before building." This is the per-epic design grill's enforcement point — the single thing that keeps the contentious naming/shape debate out of the PR.
4. **The per-PR decomposition baked in** — "#first first as its own PR; the rest follow as separate PRs (collapse only if the settled design makes the split arbitrary)."
5. **The scaled `/code-review` + ship tail** — effort dialed to blast radius, then the project's ship path.
6. **The parented-follow-ups + don't-close-the-epic rule** — out-of-scope discoveries become correctly-parented sub-issues; the PR must not close the parent if the follow-up belongs to it.

## Worked example (ADR-0019, epic A3)

A real instance, lightly trimmed — note how every blank above is filled with a concrete,
verifiable pointer:

```
Let's start A3 (#317) on the Presentational delivery board — adopt R1 structured output
(outputSchema + structuredContent) on the unblocked read/list tools. It's the next thing
now that A1 and C1 have landed.

Grounding (read before proposing):
- Planning home, waves, and priority: the Outline doc "Presentational delivery (ADR-0019)"
  — <URL>. A3 is "the first thing worth shipping at all," unblocked now that A1 is done.
- The substrate A3 builds on: A1's structuredResult() helper, the outputSchema threading
  through ToolSpec/defineTool, and the envelope conformance test (#304–307, all merged).
  Read that code and ADR-0019.
- Per-tool grading: the Outline "Tool–rung audit (66 tools)" — <URL>.

Soft sub-issue order (from the planning doc): #318 meal reads FIRST (read_meal_plan /
search_meal_history / read_recipe_history) — the rendering drops meal UIDs, the single most
harmful R1 gap — then #319 (recipe/grocery/menu lists), then #320 (catalogs/pantry/discover).

A3 has no pre-written implementation-design doc (unlike A1/C1), so designing it is part of
this. Follow the planning process in CLAUDE.md: start from current main; ground in the ADR,
the A1 envelope code, and the audit; verify the meal-UID gap in the actual rendering code
before building on it; pin "done" and "out of scope".

Show me the design and WAIT for my feedback before building. Then ship #318 first as its own
PR, #319/#320 as separate PRs; /code-review scaled to the change; ship via /ship-pr.
```

The discriminating detail: A3 carried no pre-written design doc, so "designing it is part of
this" — the kickoff explicitly folds the design step in and still gates it behind WAIT. When
an epic *does* have a pre-written design doc, point at it in Grounding instead and the design
step becomes "flesh out the existing doc."
