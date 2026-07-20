---
name: restructuring-project-docs-into-wikis
description: Use when restructuring monolithic project docs into a wiki, splitting flat reports into themed pages, or noticing duplicated disclaimers/preambles across project docs. Covers phased fan-out to parallel subagents, Outline-specific gotchas (H1 in body, relative links, anchor slugs), canonical-URL discipline for subagent prompts, and full-page verification using a Haiku checklist agent.
---

# Restructuring Project Docs Into Wikis

## Overview

Restructuring a flat doc set into a wiki has three failure modes that compound under time pressure:

1. **Phasing mistakes** — fanning out to parallel subagents that depend on each other's outputs (e.g., spawning the index page alongside the leaves it should link to)
2. **Outline gotchas** — leading H1 in doc body, unsupported relative links, fabricated anchor slugs
3. **Verification shortcuts** — trusting subagent reports because spot-checking takes time, then shipping silent bugs

This skill provides the recipe + prompt templates + verification checklist that address each. Failures are observed, not theoretical.

## When to Use

**Triggers:**
- User says "this is too monolithic" or "make this more wiki-like"
- Multiple project docs share duplicate disclaimers/footers/preambles
- A single doc has grown past ~300 lines covering many entities
- Restructuring an existing project from "report dump" into thematic pages
- Designing structure for a new project with many entities (genes, exercises, products, employees)

**Don't use for:**
- Single-doc edits or content additions (use `update_document` directly)
- Code-repo restructuring (different beast — CLAUDE.md and source layout, not wiki)
- Renaming or moving a single doc (use `move_document` directly)

## Lighter Path: Dedupe + Reframe (no fan-out)

The phased recipe below assumes you're splitting a 300+ line monolith into many leaves. **Not every restructure is that.** When the wiki already has reasonable structure and the work is primarily:

- Merging duplicate or overlapping docs into a single canonical home
- Stripping outdated content (e.g., post-hoc completion logs from a doc framed as a pre-implementation plan)
- Adding a source-of-truth pointer (e.g., the Outline space is research, the code repo is implementation status)
- Trimming title prefixes / suffixes that are now redundant given the breadcrumb
- Replacing a one-line index page with a real entry index

…then skip the parallel fan-out machinery. The flow becomes:

1. **Audit** — read everything in scope (sequential, you).
2. **Propose + Ask** — sketch the target shape, surface 2–3 genuine ambiguities via `AskUserQuestion`. **Call advisor here**, especially if user clarifications just shrunk the scope; the advisor saw the audit and can flag whether your proposed phases are overengineered.
3. **Targeted edits** — mix `editMode: patch` (surgical) and `editMode: replace` (whole-doc rewrites) per doc; archive merged-out docs. No subagents.
4. **Read each edited doc end-to-end yourself** — Haiku-checklist verification is overkill at <10 docs; reading the diffs catches the same silent bugs.
5. **Cleanup** — title polish, parent-page nav updates, verify cross-links resolve.

The full recipe (Phase A → G with parallel subagents and Haiku verification) is the right tool for genuine monolith splits with many entities. For dedupe + reframe at <10 docs, it's overkill — and the temptation to follow the recipe anyway *because the skill says so* is itself a failure mode worth resisting.

## Surface Ambiguities BEFORE Acting

Wiki structure decisions cascade. Before fanning out work, use `AskUserQuestion` to resolve:

- **Structuring axis**: by domain? by entity? by class? When user says "by X, by Y" (e.g., "by exercise type, by muscle group"), they often mean two axes — confirm whether one is top-level and the other is sub-navigation.
- **Existing data without analysis**: source files referenced but not yet processed — empty stub page, or skip until they're analyzed?
- **Local file disposition**: regenerable items (databases, generated reports, analysis scripts) — delete or keep? Even if "regenerable" sounds disposable, this is a user decision, not an agent decision. Surface every regenerable file in the inventory and ask, even when the user's directive ("just do it") sounds like blanket authorization. Authorization for the wiki restructure is not authorization to touch local files.
- **Cross-cutting entities**: where does a thing that spans multiple domains live (e.g., APOE in cardio + neuro + lipids)? Pick one canonical home and link from the others.
- **Sub-doc current-state sections drift from a parent dashboard**: if multiple docs each maintain their own "Current Medications" / "Current Settings" / "Active Status" sections, they will drift the moment state changes — written in good faith, never re-synced. During audit, list every doc that has a "Current X" section. During proposal, ask: which doc owns "what is currently true" — typically the parent dashboard. Non-canonical docs either strip their current-state sections (and add a pointer) or convert them to *historical* state (e.g., "Settings as of 2026-01-14") so they're immune to drift. Two docs both asserting current-state ownership is a contradiction trap that ships silently and only surfaces when a reader compares the two.
- **Wiki vs adjacent systems**: where does this wiki stop and another system (code repo, releases, CHANGELOG, ADRs) take over? If a doc has accumulated content that belongs in another system (e.g., post-hoc "Phase X ✅ Completed" logs in a doc framed as a pre-implementation plan), surface that disposition decision — strip / freeze with banner / move.
- **Doc claims completion that external evidence contradicts**: if a doc has `[x]` checkboxes, "Completed: <date>" markers, or status fields claiming work is done, but external evidence (no code repo, no `PROJECTS.yaml` entry, no PR refs, no commits) contradicts, surface this to the user. The markers may be aspirational placeholders from when the doc was drafted. Don't assume the doc is right — the answer determines whether markers stay (and you add a SoT pointer) or get unchecked as part of cleanup. **When the answer triggers content-correctness cleanup like this, enumerate the cleanup *before* asking** — note "if user says 'aspirational', the `[x]` markers need unchecking" so the conditional doesn't get lost in the answer rush.
- **Doc has unchecked markers despite work having shipped**: the inverse of the aspirational-`[x]` pattern. If a doc has `[ ]` checkboxes, "Testing:" sections, or "Next Steps" lists but the underlying work is actually deployed (the YAML is in the repo, the sensor is running, the binary is published), the markers are stale. Cleanup options: check the boxes (if they're genuinely re-runnable, like a verification checklist someone might run after every deploy), convert to past-tense prose, drop the section and let a `> **Status:** Shipping` banner carry the meaning, or **delete the doc entirely if it was a pre-implementation plan whose content is now canonically captured elsewhere** (repo `docs/`, code, issue tracker). The "47 checkboxes unchecked but the project is shipped on npm" pattern is a tell that the doc is a stale planning artifact, not a status record worth salvaging — the right move is delete, not cleanup. Pick based on whether the items are re-runnable, whether the doc still serves a planning purpose, or whether a canonical home for the content exists outside the wiki.
- **Local-path references in docs are claims, not facts**: if a doc cites a path like `~/Projects/foo/`, verify the directory exists before trusting it. Path references rot silently — projects get renamed, moved between machines, or migrated in/out of the synced share. A 3-way conflict (parent doc says X, `PROJECTS.yaml` says Y, filesystem has Z) is the signal that part of your restructure is reconciling the docs against current reality. Run `ls` against any local-path reference you encounter before composing the new structure; the surprise dir at a hyphen-flipped name (e.g., `mcp-paprika` vs `paprika-mcp`) is exactly where shipping status hides.
- **External URLs are claims too**: GitHub repo URLs, npm package pages, hosted doc links — all fabricable in the same way as path references. The default mental model "the GitHub user matches the local username" is wrong when a repo is owned by an org. A local repo at `~/Projects/foo/` may belong to GitHub org `foo-corp`, not the personal account that runs `git push`. Before writing a constructed URL into a doc, verify: `git remote get-url origin` for repos in the local clone, `gh repo view <owner>/<name>` for arbitrary GitHub repos, `npm view <pkg>` for npm packages. Fabricated URLs that 404 are the most embarrassing class of silent bug — they look fine in the draft, fail only when a reader clicks.

**Anti-rationalization**: "User said 'just do it' — I'll guess." That's how you ship a wiki shaped wrong and discover three days later. The 22-minute meeting deadline is fine if the *user* answers 4 quick `AskUserQuestion` items in the first 90 seconds. "Do it all" doesn't mean "guess at unresolved ambiguities" — it means "do it all without asking me what tools to use." Ambiguities about *outcome* always get surfaced.

**Self-check before asking:** before adding a question to the list, check whether your own skill rules already answer it. "Should I merge two docs that describe successive versions of the same thing?" — the Outline gotchas table calls v2/old an anti-pattern. That's not an ambiguity, it's a rule. Asking burns a question slot AND signals to the user that you don't know your own playbook. Reserve `AskUserQuestion` for genuine outcome ambiguities, not for things the skill already prescribes.

**And drop dominated options.** Same principle, different angle: if your own audit argued against an option, don't include it as a third choice "for completeness." The user reads it as a real possibility worth considering. Two options you can defend cleanly beat three with a straw man you've already invalidated. Example: if your audit found per-role Q&A is the canonical home for that content (no equivalent elsewhere), an "aggressive slim that drops the Q&A" option is dominated — your audit already refutes it. Trim before asking.

## Phased Restructure Recipe

Restructuring is **not** a fully-parallelizable task. It has hard dependencies. Follow this sequence.

### Phase A — Audit (sequential, you)
Read source docs in full. Catalog: section structure, duplicated boilerplate (disclaimers, preambles, footers — capture exact strings), entity inventory, cross-references between docs, file inventory of any local artifacts.

**Tip:** A `fetch` on the parent collection returns the entire hierarchical doc tree (IDs, titles, URLs, parent-child relationships) in one response — useful one-shot orientation that covers all docs in the collection (including sibling projects), so you can revisit any doc by ID later in the session without extra listing calls. Trade-off: ~6KB context cost for a moderately populated collection, but it amortizes well across an audit + restructure session.

### Phase B — Propose (sequential, you)
Sketch the target tree. Surface ambiguities to user via `AskUserQuestion`. Get explicit answers before fanning out. Don't write a single character of new content until the user has signed off on the shape.

### Phase C — Containers first (sequential, you)
Create the parent landing page (placeholder content OK) and any topical container docs (e.g., "Findings by Domain", "Full SNP Cross-Reference") with placeholder content. **Children need parent IDs** — fanning out before parents exist forces subagents to invent IDs or bail.

### Phase D — Leaf fan-out (parallel, subagents)
Spawn one subagent per source doc (or per content cluster) to write the leaf pages. Each subagent gets the parent container ID it should nest under, plus the source content (or a path to where it's saved).

**Critical**: subagents running in parallel **cannot cross-link to each other's outputs**. Their URLs aren't known until they return. Cross-linking pages (indexes, glossaries, "see also" sections) wait for Phase F.

### Phase E — Verify leaves (sequential, Haiku subagent)
Spawn a Haiku subagent with an explicit checklist to verify ALL leaf pages. Do not skip pages. The Haiku checklist runs in seconds and prevents downstream embarrassment. (See "Verification Discipline" below.)

### Phase F — Cross-linking pass (sequential, you or one subagent)
Now that all leaf URLs are known, create the cross-linking pages: alphabetical indexes, gene/entity registries, "see also" sections. Pass the leaf URLs **explicitly** in the prompt — never let a subagent rely on memory or pattern-guess slugs.

### Phase G — Cleanup (sequential, you)
Update parent landing with final tree. Update Playbook/About docs to reflect new structure. Delete or archive old monolithic docs. Update `PROJECTS.yaml` if applicable. **Verify before deleting** — grep across the new wiki for any references to about-to-be-deleted docs.

## Outline-Specific Gotchas

Outline ≠ standard Markdown. These bite every time:

| Gotcha | Wrong | Right |
|--------|-------|-------|
| **H1 in doc body** | First line is `# Cardio Training` | First line is body content (paragraph or `## H2`). Title is set via `title:` parameter on `create_document`. |
| **Relative links** | `[See here](../disclaimer)` | `[See here](https://outline.example.com/doc/disclaimer-XYZ)` — Outline uses absolute URLs only |
| **Anchor slugs** | `[Zone 2](#zone-2)` (assumed slug pattern) | Outline auto-generates slugs from heading text and the format isn't documented. Don't fabricate. Either link to the doc URL without a fragment, or test the actual slug Outline produces. |
| **`@mention` syntax for docs** | `@[Cardio Doc](mention://doc/...)` | `@mention` is for **users only**. Cross-doc references use plain Markdown links. |
| **Doc revisions / "v2"** | Creating new "v2" or "old" copies | Outline keeps full per-doc revision history (⋯ → History on every doc). One canonical doc; revisions handle "before/after." |
| **Trash recoverability** | Avoiding deletion "in case I need it later" | `delete_document` moves to trash, recoverable. Delete confidently after migration verification. |
| **Replace vs patch** | Always `editMode: replace` | `editMode: patch` with `findText` for surgical edits — preserves Outline-specific formatting (highlights, comments, table widths) that markdown roundtrip drops. |
| **Patch findText too short** | `findText: "## Caveats"` (matches heading, leaves bullets stranded) | Match enough text to cover the entire block being replaced. Or use `replace` with full new content. |
| **Title rename → new slug** | Renaming a doc title and assuming the URL is unchanged | Outline regenerates the slug from the new title; the urlId at the end of the URL persists, and old `slug-urlId` URLs auto-redirect. **Rename titles BEFORE writing content that references them**, or your new content will have outdated slugs that resolve via redirect — functional but not canonical. **When the new content doesn't reference the doc itself**, you can combine `title` + `text` (also works with `editMode: patch` + `findText`) in a single `update_document` call — Outline applies them atomically, so the rename-then-write order is preserved without two round-trips. |
| **Stale link text after rename** | Treating renamed-doc URLs as the only fix needed | URL slug drift after a rename is *cosmetic* — old `slug-urlId` URLs auto-redirect. But link **text** in inbound references stays stale and displays the old title. E.g., if `Editorial Draft` body has `[v1 NACHA Visualizer - Design Spec](old-url)` and you rename Design Spec to drop the v1 prefix, the link still reads "v1 NACHA Visualizer - Design Spec" until you update the link text too. Slug drift is cosmetic; link text drift is a functional bug. After bulk renames, sweep sibling docs for inbound references and update both URL and link text. |
| **`editMode: patch` silently no-ops on URL-only link changes** | Patching `[text](old-url)` → `[text](new-url)` and trusting the call's success | Outline likely stores URLs as separate fields in its rich-text representation. `findText` matches the rendered markdown and the API returns success + bumps the revision counter, but the URL doesn't propagate. Link **text** patches work fine; URL-only patches don't. **Always re-fetch after a URL-only patch** to verify ground truth — the response body of the patch call may show pre-patch content, masking the silent failure. Workarounds: use `editMode: replace` to force re-parsing (loses any rich formatting that markdown can't represent), or accept the redirect-hop since old `slug-urlId` URLs auto-redirect anyway (functional, just not canonical). The most common trigger is post-rename canonicalization sweeps — if all you're trying to fix is the URL slug, the auto-redirect already handles it; save `replace` for cases where the canonical URL actually matters (e.g., the URL is going to be copied elsewhere). |
| **Code blocks via `fetch` API** | Trusting the markdown returned by `fetch` to faithfully represent stored content | Outline's `fetch` can flatten multi-line code blocks (e.g., ASCII trees) into a single line with `` ``` ... ``` `` markers. Stored content may have proper newlines that the API normalizes. Use `editMode: patch` to avoid touching code blocks at all, or test a small replace round-trip if you need to confirm. |
| **Inline code wrapped in a link does not round-trip** | `` [`filename.md`](url) `` (markdown link wrapping inline code) | Outline silently strips the link wrapping when storing — the inline code survives, the URL is gone. The patch *appears* to land (no error, the response shows the cell rendered), but the link is missing. Verify by re-fetching the doc after writing and confirming the markdown link syntax is present. Workarounds: (1) drop the backticks — `[filename.md](url)` (plain-text link) round-trips fine; (2) keep the backticks and put the link in a parenthetical — `` `filename.md` ([GitHub](url)) ``; (3) for tables, add a dedicated "Link" column so paths stay in monospace and the link gets its own cell. Bold-around-link (`**[link](url)**`) does survive but gets re-segmented across multiple bold runs (`**text** [**link**](url)**.**`); functionally identical when rendered, but worth knowing if you later need to match the bold span via `findText`. |
| **Bold around inline code reflows when stored** | `` **`identifier`** `` (you wrote bold wrapping inline code) | Outline stores it as `` `**identifier**` `` (code wrapping bold). Renders identically in Outline's UI — same visual outcome — but the raw markdown export now has literal asterisks inside backticks. Sibling of the inline-code-in-link gotcha above. If you need to match this run via `findText` later, match the *stored* form (`` `**X**` ``), not what you originally wrote. Workaround: drop one of the two formattings (keep code, drop bold; or vice versa) if markdown export fidelity matters. For wiki-only use, leave it — Outline renders both forms the same. |
| **Sibling order = creation order, newest first** | Assuming batch-created children appear in creation order or alphabetical | When you batch-create children, Outline puts the most-recently-created first in the sidebar. If natural reading order matters (numbered tiers, alphabetical entries, sequential phases), reorder via `move_document` with an explicit `index`. **Parallel calls with absolute indexes are safe** — each specifies the final position, so they commute. Parallel calls with *relative* moves (insert-before-X) would race; do those sequentially. |
| **`tasks` metadata counter is auto-derived from body checkboxes** | Treating the counter as user-curated state | Outline auto-counts `[ ]` and `[x]` checkboxes in doc bodies into `tasks: { completed, total }` on doc metadata. A doc claiming `1/9 complete` is a tell that the body has 9 checkboxes with 1 ticked — useful at audit time for spotting stale "Next Steps" sections. Removing all checkboxes drops the counter to `0/0`, which is a clean post-cleanup signal that no actionable items remain. |
| **`revision` vs `updatedAt` for collaborative-edit auditing** | Treating the `revision` counter as authoritative for "did the content change?" | `revision` increments on view/cursor/presence events too — opening a doc in a browser tab may bump revision without changing content. `updatedAt` only moves on actual content writes. To detect concurrent overwrites (e.g., a stale browser tab clobbering your edits), compare your last-known-write timestamp against `updatedAt`, not against the revision counter. If `updatedAt` matches your last write, content is intact regardless of what `revision` shows. |

## Subagent Prompt Templates

Two patterns dominate. Both must include explicit canonical URLs/IDs — subagents fabricate plausible-but-wrong slugs from memory if you don't.

### Pattern 1: Splitting a monolithic doc

The prompt MUST include:

1. **Source content** — paste the source markdown directly into the prompt, OR give a file path where it's saved. Do not say "fetch doc X" without providing the content; fetches can fail or truncate.
2. **Parent container's exact ID** for nesting (e.g., `parentDocumentId: "7b44cb06-..."`)
3. **Literal strings to remove** — not pattern descriptions:
   - "Drop any closing footer" misses sibling variants. Source script A may emit `*Report generated by foo.py on YYYY-MM-DD...*` while script B emits `*Report generated by bar.py...*`. List **both** literal strings.
   - "Drop the disclaimer" — list the literal heading and opening sentence.
4. **Outline conventions reminder**: "No leading H1 in body. No `@mention` for cross-doc links. Use plain Markdown absolute URLs."
5. **NO cross-linking** — explicit: "Your sibling pages don't exist yet. Do not invent links to them. A separate phase will handle cross-linking once all docs are created."
6. **Expected return format**: JSON with new doc IDs and URLs, like `{"page_name": {"id": "...", "url": "..."}}`.

### Pattern 2: Cross-linking page (after Phase E)

The prompt MUST include:

1. **The full canonical URLs of every page it should link to**, in a table or list. Do not pass urlIds and ask the subagent to construct URLs — it will guess wrong on slugs and produce invented URLs that 404.
2. **The source content** (entity inventory) so the subagent knows what entries to make
3. **Explicit link form**: "Use plain Markdown links to the URLs I gave you above. Do not use relative links. Do not use anchor fragments unless I provided one."
4. **Expected return format**: doc ID + URL of the created index/registry.

**Anti-rationalization**: "I'll just remind the subagent which docs exist via the parent ID." No. **Pass the full URLs.** Subagents that try to construct URLs from a urlId or doc title fabricate plausible-looking slugs. This is observed, not theoretical.

## Verification Discipline

After Phase D (leaf fan-out), every page gets verified. **Not "the high-leverage ones" — every page.**

The failure mode is **silent**: pages look superficially fine in summaries; fabrication only shows up when a real reader follows a link.

### How to verify efficiently

Don't fetch every page yourself. Spawn a **Haiku subagent** with an explicit checklist:

```
For each page (list IDs):
  1. Pointer line at top? (the agreed-upon line, verbatim)
  2. Source-data preamble absent? (list the literal strings you want absent)
  3. Disclaimer block absent? (literal heading + opening sentence)
  4. Closing footer absent? (every variant of "Report generated by X.py..."
     you can identify in source scripts — list them all)
  5. URLs match canonical list? (provide the complete canonical URL list;
     any URL not on it is fabrication)
  6. Tables well-formed? (header + separator + data rows, no truncation)
Report: ✓ / ✗ per criterion per page. Only flag pages with issues.
```

Haiku is the right tier here: fast, follows checklists well, won't add interpretation or wander into unrelated commentary. This typically runs in 15–30 seconds for 9–10 pages.

### Anti-shortcut rationalizations

| Excuse | Reality |
|--------|---------|
| "I'll only spot-check 2 of 11" | Outline page bugs are silent. Hallucinated URLs and stranded footers don't surface in summaries. Check all. |
| "The subagent's report says ✓" | Subagent reports describe **intent**, not actual content. Trust-but-verify. |
| "The user is waiting" | Haiku verification is 15–30 seconds. Skipping it costs more than including it (silent bugs, embarrassed delivery, rework). |
| "I'll fetch back if there's a problem" | The problem is **silent**. There's never a "problem" surfaced — until a reader clicks a broken link. |
| "Pages look fine in the listing" | `list_documents` doesn't render content. Listing isn't verifying. |
| "I'll spot-check the most important pages" | The most important pages aren't where bugs hide. The lowest-traffic page may have an invented URL no one notices for months. |

### "Done" means verified, not "calls returned"

A successful `create_document` call returning a doc ID does **not** mean the doc is correct. "Done" means: created, verified by Haiku checklist, cross-links resolved, parent landing updated, old monolith deleted/archived, and `PROJECTS.yaml` (or equivalent) updated. Anything less is "in progress."

## Path References for `~/Sync/...` Projects

For projects whose local files live in `~/Sync/` (Syncthing-synced across devices), use the share label + folder ID convention in any inventory you write to Outline:

```
Synced share:   Home  (Syncthing folder ID: <id>)
Relative path:  Working/projects/<name>/
```

`~/Sync/...` is macOS-only on the local machine; the folder ID is portable across all peers. Tag files in inventories by replaceability — ✅ regenerable / ❌ irreplaceable — so backup priorities are obvious. Regenerable build artifacts (databases, generated reports) shouldn't be left in the synced share if they're large.

## Surfacing Loose Threads After the Initial Pass

After the initial restructure lands, you'll often notice deeper cleanup that's *related but bigger scope* than the original ask. Examples: two sibling docs whose Decisions sections overlap; a section accumulating content that belongs in another system; a hidden "v1/v2" pattern in parenthetical titles like "(Post-Critique)" or "(Old)"; a resolution doc that contains literal "update the parent doc to ..." instructions that were never applied.

Don't unilaterally extend scope. Don't bury the findings either. Surface them with tiered options so the user can invite the extension:

- **Minimal**: fix only the active bugs — stale headings, contradictions, unresolved "update the parent doc to ..." instructions buried in resolution docs.
- **Medium**: convert duplicate content to TL;DR + pointer at the canonical home. Eliminates duplication without changing the role of either doc.
- **Full**: absorb the secondary doc's content into the canonical home and archive the secondary doc. Resolves duplication AND the v1/v2 anti-pattern.

Be concrete about what each tier touches and the role-shift it implies. Full-tier merges change the *role* of the docs involved — that's an editorial decision, not a structural one, and belongs to the user.

**Don't include time estimates in the tiers.** They're consistently wrong, the user has no way to verify them, and they create friction when they slip. Scope and risk are what the user is choosing between, not duration.

### Stub Docs for Known-Future Tracks

When a user mentions a planned intervention, project track, or research path that has no doc yet (e.g., "we're going to do an orthodontic intervention," "the prescriber visit is next week," "I'll add the sleep studies later"), create a **stub doc immediately** with a "To document" checklist — don't wait for the research/data to exist.

The cost of placement (location in tree, title, cross-links) is the same whether the doc is full or empty. Deferring means re-deciding placement later, possibly under time pressure when the data finally arrives. A stub anchors the topic in the sidebar and gives a single home for future content.

The stub should include: a one-paragraph framing of how it relates to existing wiki content, a "To document" checklist of what will fill it (provider/plan/timeline/etc.), and cross-links to existing docs the track interacts with. If the parent dashboard has a TODO section, point at the stub from there ("document X as it develops — add to [stub URL]") so the user has a clear capture path next time they have material.

Tiers can absorb stub creation as an extension. If the user's loose-thread question reveals a known-future track, fold the stub into your Full tier as a low-cost addition; don't spawn it as a separate question.

## Architecture vs Decisions: Canonical Split for Design Docs

When merging overlapping decision content (most often during a Full-tier loose-thread merge), use this split as the organizing principle:

- **Architecture** = *what it does*: mechanism, lifecycle, sync flow, data model, API surface. The "how it behaves" reference.
- **Decisions** = *what we chose and why*: rationale, tradeoffs, alternatives considered, scope-cuts. The "why this and not that" log.

Where both sections describe the same thing, slim the Decisions side to a pointer like *"See Architecture > X for the mechanism."* Keeps the rationale traceable in the Decisions section without duplicating the description that belongs in Architecture.

Inverse fails: putting mechanism in Decisions bloats the section with implementation detail; putting rationale in Architecture buries the why under the how.

This applies any time a doc has both a "how it works" section and a "why we chose this" section that risk drifting apart — including project parent docs, design specs, and ADR-style documents.

## Adjacent Backlog Systems: Snapshot, Don't Mirror

When the project has a live issue tracker (GitHub issues, Linear, JIRA), the wiki backlog must not try to mirror it — they will drift the moment an issue is opened or closed. The tracker is the canonical home for "what's open"; the wiki's job is to point at it and (optionally) snapshot what was open at restructure time.

- **Point at the live tracker as the canonical backlog.** A direct link to the issues filter is enough for projects with low churn. For higher-leverage or higher-traffic projects, add a snapshot table so a reader sees at-a-glance whether anything operationally important is open.
- **Date every snapshot.** A table of open items is useful at-a-glance context only if a future reader knows it's frozen. Lead with `Snapshot as of YYYY-MM-DD:` so the table doesn't age into a lie that contradicts the live tracker.
- **Operationally-critical items get a Scope-notes mention with workaround inline**, not just a backlog row. A live bug affecting current users is operator-facing right now, not roadmap. Burying it in a backlog table treats it as future work and delays the moment a reader sees the workaround. Example: a stdio-corrupting bug in the published version of an MCP server belongs in Scope notes ("known issue + how to work around it"), with a cross-reference from the backlog row.
- **Auto-generated bot items are not features.** Renovate's Dependency Dashboard, Dependabot summary issues, etc. should be called out explicitly so a reader doesn't mistake them for tracked work.

**Snapshot format that works:**

```
## Backlog

Live in [GitHub issues](https://github.com/owner/repo/issues). Snapshot as of YYYY-MM-DD:

| Issue | Type | Summary |
|-------|------|---------|
| [#49](url) | Bug | one-line summary; cross-ref Scope notes if operator-facing |
| [#22](url) | Feature | one-line summary; cross-ref Scope notes if elaborated above |
```

**Anti-rationalization**: "The wiki said no open backlog, so it's clean." That confidence is fake until you've checked the tracker. Before declaring a wiki restructure done on a code-adjacent project, run `gh issue list --state open` (or the equivalent for the project's tracker). If issues exist, the wiki's backlog section needs to acknowledge them — by snapshot, by pointer, or by ack of the bug-vs-feature split. This often only surfaces when the user nudges ("did you check GitHub?"); don't wait for the nudge.

## Private Corpus, Public Artifact: When the Wiki Is the Source

The inverse of the deferral patterns above. The wiki is the canonical home for the **rich source material** that produced a trimmed public artifact — and the source material has no equivalent home elsewhere.

Examples: a CV/resume project where the public site has the trimmed CV but the wiki has the full interview Q&A, narratives, and sensitive metrics. A talk where the slides are public but the wiki has the speaker notes and supporting evidence. A design proposal where the published spec is public but the wiki has the unredacted reasoning, scrapped alternatives, and decision rationale that didn't make the final document.

**Pattern characteristics:**

- **Public artifacts are trimmed outputs.** Bullet-form, audience-tuned, sensitive details stripped.
- **Wiki keeps the full source material.** Q&A with detail that didn't make the bullets, internal metrics, narrative scaffolding, alternatives that got cut.
- **Sensitive markers** (`[NOT PUBLIC]`, `[SENSITIVE]`, `[INTERNAL]`) tell readers and agents what doesn't propagate.
- **The wiki has no equivalent home elsewhere.** Losing the wiki content loses information that isn't anywhere else — distinct from the Paprika-style case where the repo `docs/` is canonical.

**Parent-doc framing for this pattern.** Make the public/private relationship explicit so a future reader (and future-you on the next refresh) doesn't have to reconstruct why both layers exist:

```markdown
## Public Outputs

| Artifact | Location |
|---|---|
| Rendered (audience-facing) | https://example.com/cv |
| Source (versioned)         | https://github.com/.../cv.md |
| PDF (downloadable)         | https://example.com/cv.pdf |

## Why two tiers?

Public artifacts are trimmed outputs: bullet-form, audience-tuned, sensitive details stripped. This wiki keeps the full source material — Q&A with detail that didn't make the bullets, internal metrics, narrative scaffolding, and items marked sensitive that don't go public. The Outline space is intentionally private; the public surface is the published artifact.
```

**Distinguishing from the deferral pattern.** Two restructures with the same surface shape (parent + N children, post-shipped state) can have opposite right-answers depending on this distinction. If the canonical home for the *content* lives elsewhere (repo `docs/`, published spec, issue tracker), the wiki should slim to a hub-and-pointer. If the canonical home for the *source material* is the wiki and only the *trimmed output* is public, keep the source material rich and tag what's sensitive. The call is made at audit time, not after fanning out — and previous-restructure pattern-bleed is a real failure mode (see Red Flags).

## Common Mistakes

Technical errors that show up repeatedly:

| Mistake | Fix |
|---------|-----|
| Spawning all subagents in one parallel burst | Phase first. Containers → leaves (parallel) → verification → cross-links. |
| Subagent writes `# Title` as first line of doc body | Outline stores title separately. Body starts with first paragraph or `## H2`. |
| Cross-linking page uses placeholder anchors / relative links | Build it AFTER siblings exist. Pass canonical absolute URLs in prompt. |
| Verification spot-checks only "high-leverage" pages | Haiku checklist runs ALL pages in seconds. Skip nothing. |
| "Done" declared on `create_document` returning a doc ID | Done means verified + cross-linked + cleanup complete. |
| Surfacing zero ambiguities to user before fanning out | `AskUserQuestion` with 2-4 items in the first 90 seconds. |
| Patch-mode `findText` matches a partial section, leaves bullets stranded | Either use `editMode: replace` with full content, or `findText` long enough to match the entire block. |
| Sibling subagents told to "link to your siblings when ready" | They can't. Defer cross-linking to Phase F. |
| Migration prompt says "drop the closing footer" | Sibling source scripts emit different footer variants. List **literal strings**, plural. |
| Subagent prompt says "construct URLs from the parent's URL" | Subagent guesses wrong slugs. Pass full canonical URLs. |
| Renaming doc titles after writing content that links to them | Rename first, then write linking content with the new canonical slugs. If you must rename later, run a cleanup pass to update inbound URL slugs (or accept redirect-hop links as cosmetic-only). |
| Following the full Phase A→G recipe for a small dedupe/reframe job | Use the lighter path (5 steps, no fan-out, no Haiku) when the wiki already has reasonable structure. The full recipe is for monolith splits, not for merging 3 overlapping research docs. |
| Batch-creating children and forgetting to reorder them | Outline defaults to newest-first in the sidebar. After batch creation, send `move_document` calls with explicit `index` values (parallel-safe; each specifies absolute position). Otherwise a tiered/numbered/alphabetical set ships in reverse order. |
| Treating `[x]` / "Completed: <date>" markers as ground truth | When the doc claims completion but external evidence (code repo, PR links, `PROJECTS.yaml`) contradicts, ask. Markers can be aspirational placeholder content from when the doc was drafted. |
| Trusting `editMode: patch` to rewrite the URL portion of an existing markdown link | Patches to URL-only changes silently no-op. Re-fetch after the call to verify ground truth. Use `replace` if the canonical URL matters and the body has no rich formatting to preserve; otherwise accept the cosmetic redirect-hop. See the gotchas table for full mechanism. |
| Sub-docs maintaining their own "Current Status" / "Current Medications" / "Active Settings" sections alongside a parent dashboard | They will drift. During audit, list every "Current X" section across the wiki and ask the user which doc is canonical. Strip the non-canonical ones or convert them to dated historical state ("Settings as of YYYY-MM-DD"). |

## Red Flags — STOP

If you find yourself reasoning any of these, you're rationalizing toward a known-bad path:

- "Spot-checking all pages takes too long" → Haiku does it in 30 seconds
- "The subagent's summary said it created the docs correctly" → summaries describe intent, not result
- "I'll skip Phase E and do Phase F first to save time" → F depends on E; you'll fabricate URLs
- "I'll guess on the IA ambiguity" → wrong-shaped wiki is worse than slow wiki
- "The user said 'just do it'" → they want it done **right**, not done fast and broken
- "I'll declare done when `create_document` calls return" → that's "in progress," not "done"
- "I'll use anchor links and they'll probably work" → they probably won't; Outline's slug format isn't documented
- "The disclaimer pattern in this report is unique to this report" → sibling reports have variants; list **all** literal strings
- "The user is waiting in a meeting" → 90 seconds for `AskUserQuestion` + 30 seconds for Haiku verification is faster than re-doing the wiki
- "I'll tell the subagent to verify itself" → subagents verify their own intent, not their own output
- "Regenerable means safe to delete" → regenerable means regenerable, not disposable. The user decides what stays in their filesystem. Ask before any local deletion.
- "The wiki authorization implies file-management authorization" → it doesn't. Restructuring an Outline wiki is a doc operation; touching local files is a separate decision that needs its own consent.
- "The previous restructure had pattern X, so this one will too" → run a fresh audit. Two restructures with similar surface shape (parent + N children, all created the same day, post-shipped state) can have opposite right-answers because the children's role differs (redundant copies of canonical-elsewhere vs. canonical source for trimmed-public-output — see *Private Corpus, Public Artifact*). Pattern-bleed from a recent session is observed, not theoretical.

All mean: follow the recipe.
