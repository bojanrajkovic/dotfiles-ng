---
name: starting-a-new-project
description: Use when starting a new project from scratch — "I want to track X", "set up a project for Y", "start a project for Z", "begin tracking W". Covers mandatory pre-creation questions (scope / artifact-bearing or pure-doc / location / initial structure), Outline collection placement, PROJECTS.yaml discipline, and wiki-from-day-1 structure to prevent flat single-doc projects that need restructuring later. Cross-references restructuring-project-docs-into-wikis for shared Outline conventions.
---

# Starting a New Project

## Overview

New project setup is **high-ambiguity, low-urgency** work. The user knows what they want to track; they don't know (and shouldn't have to specify) what scope, what location, or what initial structure best matches the project's likely trajectory. The agent's job is to surface these decisions, not to make them.

The dominant failure mode is **action bias** — diving in to "do useful work" with speculative dirs, speculative docs, speculative `PROJECTS.yaml` entries — and then surfacing the assumptions in a TODO block or post-hoc disclosure. This guarantees re-do work later and creates clutter that's hard to undo cleanly. Ask first; create second.

## When to Use

**Triggers:**
- "I want to start a new project for X"
- "Set up a project to track Y"
- "Begin tracking Z"
- "Help me organize a new effort around W"
- User describes a new domain they want a structured place for

**Don't use for:**
- Adding to an existing project (use `update_document` and direct edits)
- Single-doc captures (use `journal`, `memory`, `idea` skills instead)
- Restructuring an existing project (use `restructuring-project-docs-into-wikis`)

## Mandatory Questions Before Any Creation

Before creating any Outline doc, local directory, or `PROJECTS.yaml` entry, surface these via `AskUserQuestion`. **All four are mandatory** unless the user has already volunteered the answer in their initial message.

### 1. Scope — what's in / out?

The user gave a phrase like "track home server hardware." That phrase has 5+ legitimate interpretations:
- Just the physical machines? Or also the network gear?
- Hardware only, or hardware + the OS / software / VMs running on it?
- Production equipment only, or also dev/test boxes?
- Owned hardware only, or also rented (VPSes, cloud)?

Ask: "What's in scope and what's explicitly out of scope?"

### 2. Artifact-bearing or pure-doc?

Three project shapes exist in this workspace:

- **Pure-doc** — only Outline content (e.g., Resume, Olivia's research). No local files, no `PROJECTS.yaml` entry.
- **Data-bearing** — Outline + local data files (CSVs, JSON exports, scripts) at `~/Sync/Working/projects/<name>/`. `PROJECTS.yaml` entry yes.
- **Code-adjacent** — Outline + a code repo (typically at `~/Projects/<name>/` or `~/Sync/Working/projects/<name>/`). `PROJECTS.yaml` entry yes.

Ask: "Will this project have local files (data, scripts, or code)? If yes, code repo or data files?"

**Follow-up if code-adjacent — clarify the source-of-truth boundary** between Outline and the repo. Common patterns:

- **Outline = pre-implementation, repo = current state** — Outline holds research, design notes, prior-art deep dives, and the plan the repo grew out of. The repo's `docs/`, ADRs, releases, CHANGELOG are authoritative for current architecture and "what shipped." The Outline parent should say so explicitly with a "Source of truth: github.com/..." banner so future readers (and agents) don't accumulate stale implementation status in Outline.
- **Outline = wiki, repo = just code** — repo has minimal docs (a README); Outline is canonical for everything else.
- **Mixed ownership** — Outline owns some topics (vision, prior art, ADR drafts), repo owns others (current architecture, deployment); document the split on the parent landing.
- **Outline = pre-implementation, repo doesn't exist yet** — different from the first pattern because there's no URL to point at. Architecture / design / build plan are drafted in Outline; implementation hasn't started. Parent landing should say `> **Status:** Pre-implementation. The code repo will be linked here when work begins.` instead of a "Source of truth: github.com/..." banner. When implementation kicks off, replace the status banner with the SoT pointer.
- **Outline = private source corpus, repo = public trimmed artifacts** — distinct from the first pattern because both layers are *current*, not pre-implementation vs current. The repo (and its rendered/downloadable outputs) is the public surface; Outline keeps the full source material with sensitive markers, internal metrics, and detail that doesn't make the polished artifact. Common for: resumes/CVs, executive narrative libraries, talks/papers with private speaker notes or research backing, design proposals with sensitive vendor or budget detail. Parent landing should explicitly call out the public/private relationship and link to all public artifacts. See *Private Corpus, Public Artifact* in `restructuring-project-docs-into-wikis` for the parent-doc framing template.

**Whichever pattern fits, the backlog axis is separate from the content axis.** If the project has (or will have) a live issue tracker — GitHub issues, Linear, JIRA — the wiki should treat the tracker as the canonical backlog and point at it, not try to mirror it. A wiki "Backlog" section that enumerates open work will drift silently the moment an issue is opened or closed. See *Adjacent Backlog Systems: Snapshot, Don't Mirror* in `restructuring-project-docs-into-wikis` for the snapshot pattern. For brand-new projects with no tracker yet, the parent landing's TODO/roadmap section is fine — but call out the migration when a tracker comes online.

**When the parent doc carries substantial design content** (typical for the pre-implementation case above), organize it with the canonical **Architecture (what it does) vs Decisions (what we chose and why)** split from day 1 — see *Architecture vs Decisions: Canonical Split for Design Docs* in `restructuring-project-docs-into-wikis` for the full convention. Don't create a separate "(Post-Critique)" or "(v2)" sibling decision doc; keep one `## Decisions` section in the parent and use Outline's revision history for before/after. Pre-implementation projects are most prone to this anti-pattern because the design phase generates a lot of decision content that feels like it deserves its own home — it doesn't.

**Code-adjacent parent landing carries the repo tour, not just a nav index.** When scope is "minimal-now, grow-as-needed" and the repo already has substantial artifacts (existing automations, configs, scripts, sub-modules), the parent landing's job is to *contextualize what's on disk* so it isn't a vacuum. The shape:

- About paragraph (what this project is)
- SoT pointer (Syncthing share-label if the repo lives in `~/Sync/`, GitHub URL otherwise)
- "What lives in the repo" overview section — directory layout, counts, brief description of each top-level area
- Index of any current notes (Outline child docs, if any exist)
- "To document later" TODO list of non-obvious decisions currently captured only in the YAML / code

**For the layout overview, prefer a 3-column table — `Path | Description | GitHub link` — over a 2-column shape that tries to make the path itself a clickable link.** Outline silently strips the link wrapping around inline-code (`` [`path`](url) ``), so a 2-column table that combines monospace path + GitHub URL in one cell will lose the link on round-trip. The 3-column shape keeps paths in monospace AND preserves clickable links. See the inline-code-link gotcha in `restructuring-project-docs-into-wikis` for details.

Don't write detailed child docs speculatively — that's the user's call, made when they have bandwidth and a specific topic. Do describe the shape of the repo. The parent acts as the table-of-contents-plus-tour for a repo that's much larger than the Outline space documenting it.

Getting this boundary wrong means accumulating implementation status in the wrong system, then needing to strip it later (the kind of work `restructuring-project-docs-into-wikis` exists to handle).

### 3. Existing data?

Is the user starting from zero, or do they have data/notes/exports to incorporate?

- "Starting fresh" → seed parent + About; populate as work progresses
- "I have an export I want to import" → factor into structure (raw data goes where? processed views go where?)

Ask: "Do you have any existing data, exports, or notes to migrate in, or are we starting from scratch?"

### 4. Initial structure preference

Even with scope known, the structure has degrees of freedom:

- **Minimum**: parent doc only, grow organically
- **Standard seed**: parent + About + 1–2 themed children matching the major axes
- **User-specified**: user has a structure in mind

Ask with concrete options. Don't make the user invent structure from nothing — propose 2–3 trees and let them pick.

## Anti-Rationalization for Asking

The action-bias rationalizations to resist:

| Excuse | Reality |
|--------|---------|
| "Specific enough to make reasonable decisions" | "Specific enough" means *you* can construct *a* reasonable interpretation. The user's interpretation may differ in ways that compound. |
| "Starting with a skeleton + TODO sections is faster" | TODOs in a wrong-shaped project don't get fixed; they ossify. The shape persists. |
| "I'll surface issues mid-work as notes" | Mid-work surfacing means the user reviews after the bad shape exists, with sunk cost on both sides. Pre-creation surfacing means the shape is right from byte 1. |
| "Asking 4 questions takes too long" | 4 questions in `AskUserQuestion` arrive in one screen. The user answers in 90 seconds. Wrong-shape rework costs 30+ minutes. |
| "The user said 'just set it up'" | "Set it up" authorizes the *action*. It does not authorize *every design decision* on their behalf. Asking is part of setting it up. |

## Project Type Decision Tree (after Q2 answered)

| Answer | Outline | Local dir | `PROJECTS.yaml` |
|--------|---------|-----------|-----------------|
| Pure-doc | Yes (Projects collection) | **No** | **No** |
| Data-bearing | Yes (Projects collection) | `~/Sync/Working/projects/<slug>/` | Yes |
| Code-adjacent | Yes (Projects collection) | `~/Projects/<slug>/` *or* `~/Sync/Working/projects/<slug>/` (ask) | Yes |

**Hard rule on `PROJECTS.yaml`**: only artifact-bearing projects (data or code) get an entry. Pure-doc projects don't. The file's purpose is to map slug → local path; with no local path, there's nothing to map.

**Hard rule on local dirs**: never create a local directory without explicit answer to Q2. If the user said "data-bearing" or "code-adjacent," create the dir. If they said "pure-doc" or didn't answer, don't.

**Verify the path doesn't already exist before creating.** Run `ls ~/Projects/<slug>` (or the appropriate parent) before `mkdir`. A pre-existing directory at the proposed slug means either the project was already started under a different name (slug collision) or the user has unrelated work at that path — either way, it's a question for the user, not an action you take. Watch for hyphen-flips and near-misses (`mcp-foo` vs `foo-mcp`) — these are exactly the silent collisions that cause path confusion later when docs cite one name and the filesystem has another.

## Initial Structure (Wiki from Day 1)

Even minimal projects start with at least:

- **Parent doc** (= project landing page). Contains: 1-line scope, link to About, link tree of any children, key context.
- **About** (= canonical reference). Contains: scope statement, glossary if needed, data sources & file inventory if data-bearing, caveats if any. This is where the *one canonical home per concept* principle starts paying off — every later doc points here.

If the user picked "standard seed," add 1–2 themed children based on the project's major axes. Examples:
- Hardware tracking → "Hardware Inventory" + "Maintenance Log"
- Personal medical research → "Conditions" + "Medications"
- A learning project → "Notes" + "Open Questions"

**Don't seed more than 2 themed children on day 1.** The wiki shape can grow as content arrives. Empty docs are clutter; they invite filling them with speculative content.

## What NOT to Create Speculatively

When in doubt about whether to create something, don't.

- **Empty subdirectories** (`scripts/`, `inventory/`, `data/`) "reserved for future use" — the directory does no useful work until there's a file in it. Create when needed.
- **`README.md` in local dirs** — Outline parent doc already serves as the project landing page. A local `README.md` duplicates work and drifts. Only create if the project becomes a public/shared code repo.
- **Empty Outline child docs** as placeholders for future themes — empty docs in Outline's tree are visual noise. Create when you have content.
- **`git init` in the local dir** — only if there's code (or going to be code very soon). Personal data dirs don't need git unless the user asks.
- **Schema validators / linters / pre-commit configs** for projects that don't have committed code yet.
- **Pre-checked acceptance criteria** as `[x]` placeholders — ACs should start as `[ ]` and get checked when actually done. Aspirational `[x]` creates a content-correctness bug that someone (probably an agent on a future restructure) has to reconcile against external reality. Same applies to "Completed: <date>" markers, "✅" headings, and any other signal of done-ness on work that hasn't actually shipped.

## Outline Conventions Recap

The full Outline gotchas list lives in `restructuring-project-docs-into-wikis`. The most important ones for new project setup:

- **No leading H1 in doc body** — Outline stores titles separately. Body starts with first paragraph or `## H2`.
- **`@mention` is for users only**, not cross-doc links. Cross-doc links use plain Markdown to absolute URLs.
- **Doc revisions are your version history** — no "v2" or "old" docs. One canonical doc per concept.
- **Outline trash is recoverable** — delete confidently, restore if needed.

## Slug & Naming Conventions

- **Slug**: kebab-case, descriptive, unambiguous. `home-server-hardware` not `servers` or `homelab-hw`. Match the slug to the Outline doc title (in human-readable form). Example: slug `nacha-visualizer` → title "Nacha Visualizer".
- **Outline doc title**: title-case, no emoji prefix needed (Outline icon param handles that). The title is what `mcp__claude_ai_Outline__create_document` puts in the `title:` parameter, NOT a leading `# H1` in the body.
- **`PROJECTS.yaml` entry fields**: `name` (slug), `outline_id`, `outline_url`, `local_path`, `description` (one-liner). Fill `outline_id` and `outline_url` from the actual create response — never with placeholders. The same discipline applies to any external URL you write into the parent doc — verify GitHub repo URLs (`git remote get-url origin` if local, `gh repo view <owner>/<name>` for arbitrary), npm package pages, hosted doc URLs. The "GitHub user matches local username" assumption fails for org-owned repos and produces fabricated URLs that 404 only when a reader clicks.

## PROJECTS.yaml Discipline

After the parent Outline doc is created, append the entry. **All five fields filled with real values, not placeholders.**

```yaml
- name: <slug>
  outline_id: <UUID returned by create_document>
  outline_url: <URL returned by create_document>
  local_path: <absolute path to local dir>
  description: <one-line description, ~10–15 words>
```

Hard rule: never commit `outline_id: <UUID>` placeholders. Either you have the real ID (because you just created the doc) or you don't (in which case you haven't created the doc yet, so don't write the entry).

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Diving into doc creation without asking 4 questions | Surface them up front. 90 seconds beats 30-minute rework. |
| Adding `PROJECTS.yaml` entry for a pure-doc project | YAML is for artifact-bearing projects only |
| Creating `~/Sync/Working/projects/<name>/` because "the pattern" | Confirm artifact-bearing first. Don't assume the path. |
| Creating empty `scripts/` and `inventory/` subdirs | Create directories when there's a file to put in them |
| Creating `README.md` in a non-code local dir | Outline parent serves that role; don't duplicate |
| Seeding 5 child docs to "establish structure" | 2 max on day 1. Grow with content. |
| Putting "TBD" or "TODO: get real ID" in `PROJECTS.yaml` | Create the doc first, then write the entry with real values |
| Setting Outline doc body to start with `# Title` | Outline `title:` parameter handles titles; body starts with content |

## Red Flags — STOP

If you find yourself reasoning any of these, you're rationalizing toward action bias:

- "The request is specific enough to skip questions" → "specific enough" doesn't bind their interpretation to yours
- "I'll set up the skeleton and put TODOs in it" → TODOs in a wrong-shaped skeleton don't get fixed
- "Asking takes too long" → 4 questions in one `AskUserQuestion` call, ~90 seconds total
- "I'll match the pattern of similar existing projects" → patterns are good defaults but not commitments; ask before assuming
- "I'll create the local dir and they can move it later" → creating it commits a decision; moving it later is friction
- "PROJECTS.yaml is harmless to add proactively" → it's the index of artifact-bearing projects; pure-doc entries pollute the contract
- "I'll create scripts/ and inventory/ now to establish convention" → convention emerges from real files, not empty dirs
- "Slugs are arbitrary, mine is fine" → slugs are user-facing; ask if there's a preferred form
- "I'll fill in `outline_id: TBD` for now" → never. Create the doc first. The ID is a real value, not a placeholder.
- "The user said 'just do it'" → "do it" includes asking the questions that determine what "it" is

All mean: ask first, create second.
