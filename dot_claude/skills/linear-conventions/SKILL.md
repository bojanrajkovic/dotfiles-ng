---
name: linear-conventions
description: >-
  How to model a body of work in Linear — the hierarchy (initiatives, projects,
  milestones, issues), how to write issues, and the MCP tooling gotchas. Use this
  WHENEVER you are about to create or restructure work in Linear: standing up an
  initiative or project, breaking an epic into milestones/issues, filing a batch of
  tickets, wiring blocked-by dependencies, or deciding initiative-vs-project-vs-issue.
  Trigger even when the user just says "file these in Linear", "set up the project",
  or "make issues for this" — the conventions and the tooling gotchas here save real
  round-trips and prevent mis-modeled work.
---

# Modeling work in Linear

This skill captures three things that travel together: **Linear's method** (how
Linear intends work to be shaped), **our house conventions** (how we apply it), and
the **MCP tooling gotchas** (what the Linear MCP can and can't do, learned the hard
way). Follow it whenever you stand up or restructure work in Linear so the structure
is idiomatic and the filing doesn't waste round-trips.

## The hierarchy — pick the right altitude

```
Initiative   strategic; GROUPS MULTIPLE PROJECTS toward a goal over a long horizon
  └ Project  one time-bound DELIVERABLE (e.g. "launch X"); holds issues + milestones
      └ Milestone   a completion STAGE / phase within the project
          └ Issue   one concrete task (+ sub-issues only when it must be split)
```

- **Cycles** are sprints (time-boxed, recurring) — operational, optional, orthogonal
  to the above. Don't reach for them unless the user runs cycles.
- **Labels** are cross-cutting grouping (type/area), independent of the tree.
- **Relations** (`blocked-by` / `blocking`) are the dependency DAG — this is what
  encodes order, not issue numbers (issue numbers are creation order, never a
  schedule).

**Choosing the altitude is the most common mistake.** A 1:1 initiative→project is an
anti-pattern: initiatives exist to group *several* projects. If a "big chunk" will
itself fan into multiple deliverables (a months-long rebuild → schema, migration,
cutover), it's an **initiative**, not a project. If it's one coherent deliverable,
it's a **project** whose phases are **milestones**. When unsure, ask: "does this
decompose into multiple independently-shippable deliverables?" Yes → initiative.

## Writing issues — "issues, not user stories"

Linear's method (https://linear.app/method/write-issues-not-user-stories) in practice:

- **Short, plain-language, concrete task with a defined outcome.** Title states the
  task and scans cleanly in a list. Skip the "As a user, I want…" ceremony.
- **Break features into small, tangible pieces.** Our bar: **one issue ≈ one
  small PR** (a few hundred lines at most) so it's easy for a human and an AI to
  review and unlikely to need rework. If an issue hides two seams, split it; keep
  risk classes apart (a mechanical deletion shouldn't ride with a decision-gated
  change).
- **Placeholder issues are fine for genuinely exploratory work** ("Spike: …",
  "Flesh out the X design") — but don't stuff a vague, needs-fleshing-out idea into
  an issue as if it were a task. That belongs in a project description or an Outline
  doc, with a placeholder issue pointing at it.
- **Scope projects down** into manageable chunks; prefer more small issues over a few
  big ones.

### Our issue body shape (lean)

Keep descriptions minimal but actionable. A good default:

```markdown
<one-line what + why>

**Done**
- [ ] concrete check (name the exact files/tools in scope so the PR boundary is clear)
- [ ] …

—
Part of **<project>**. <provenance — e.g. "Private fork of mcp-paprika.">
```

Name exact files/symbols when you know them (it pins the PR boundary), but avoid
pasting large stale snippets — they rot. A decision/ADR-bearing issue's "Done" is the
ADR written + rationale captured, not code.

## Our house conventions

- **Milestones = phases/epics** of the project; issues hang off them. When two phases
  have different bars (e.g. private-beta vs public-GA), make them separate milestones
  and let `blocked-by` carry "GA needs this beta thing first."
- **Label set** (create per-team if absent): `decision` (a real fork to adjudicate,
  often ADR-bearing), `spike` (time-boxed investigation), `architecture` (system/data
  design), `design` (UX/visual), `infra` (deploy/CI/runtime), `docs`, `chore`
  (mechanical: renames/deletes/config/sweeps). Add domain labels (`legal`,
  `marketing`, …) when a body of work needs them — don't invent labels nobody filters
  on.
- **Future bets = a placeholder project** (or placeholder issue) with one exploratory
  item + a pointer to the canonical Outline doc, rather than a pile of speculative
  issues. Keep the fleshing-out in the doc until it's real.
- **The DAG is the schedule.** Wire `blocked-by` for every real dependency
  (decision→implementation, spike→build, substrate→consumers); don't rely on issue
  order. "What's next" = "what's unblocked."
- **Cross-link to Outline.** When the doc layer (Outline) and the tracker (Linear)
  both describe the work, link them both ways: a "Tracking" section in the Outline doc
  pointing at the initiative/projects, and project descriptions pointing back at the
  canonical doc.

## MCP tooling gotchas (the Linear MCP)

These are real limitations of the Linear MCP tools — plan around them:

- **No initiative creation and no `list_initiatives`.** You cannot create an
  initiative or enumerate initiatives via the MCP. Have the **user create
  initiatives in the Linear UI**, then attach projects with
  `save_project(addInitiatives: [<initiative-id>])`. Get the id from the initiative
  URL (`/initiative/<uuid>`). There's a `save_milestone` for project milestones, so
  milestones are scriptable; initiatives are not.
- **Reference by name where you can.** `save_issue` accepts `project`, `milestone`,
  and `labels` by **name** (and `team` by name or id), so you don't need to capture
  every id — but you **do** need issue identifiers (e.g. `HOL-42`) from create
  results to wire relations.
- **Wire relations in a second pass.** Create all issues first (parallelizable),
  capture their `HOL-N` identifiers from the results, then `save_issue(id, blockedBy:
  [...])`. `blockedBy`/`blocks`/`relatedTo` are append-only (existing relations are
  never removed).
- **Don't HTML-escape `&` in names/titles.** Pass a literal `&` — writing `&amp;`
  lands the literal string "&amp;" in the title/name. (If it slips through, fix with a
  follow-up `save_issue`/`save_project` update.)
- **Issue numbers are workspace-global and may not start at 1** — don't assume the
  first issue you create is `<KEY>-1`.

## Filing order (dependency-safe)

When standing up a fresh body of work, create in this order so every reference
resolves:

1. **Labels** (independent) — `create_issue_label` per team; skip ones that exist
   (`list_issue_labels` first on an established team).
2. **Initiatives** — ask the user to create them in the UI (see gotcha) if they don't
   exist yet; collect the ids.
3. **Projects** — `save_project(addTeams: [...], addInitiatives: [...])`.
4. **Milestones** — `save_milestone(project, name, …)`.
5. **Issues** — `save_issue(team, project, milestone, labels, title, description)`;
   capture the `HOL-N` identifiers.
6. **Relations** — second pass of `save_issue(id, blockedBy/relatedTo)`.

Batch independent creates in parallel; sequence only across the dependency steps.
Present the proposed structure for approval **before** filing a large batch.
