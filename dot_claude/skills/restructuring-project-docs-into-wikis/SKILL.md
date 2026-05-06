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

## Surface Ambiguities BEFORE Acting

Wiki structure decisions cascade. Before fanning out work, use `AskUserQuestion` to resolve:

- **Structuring axis**: by domain? by entity? by class? When user says "by X, by Y" (e.g., "by exercise type, by muscle group"), they often mean two axes — confirm whether one is top-level and the other is sub-navigation.
- **Existing data without analysis**: source files referenced but not yet processed — empty stub page, or skip until they're analyzed?
- **Local file disposition**: regenerable items (databases, generated reports, analysis scripts) — delete or keep? Even if "regenerable" sounds disposable, this is a user decision, not an agent decision. Surface every regenerable file in the inventory and ask, even when the user's directive ("just do it") sounds like blanket authorization. Authorization for the wiki restructure is not authorization to touch local files.
- **Cross-cutting entities**: where does a thing that spans multiple domains live (e.g., APOE in cardio + neuro + lipids)? Pick one canonical home and link from the others.

**Anti-rationalization**: "User said 'just do it' — I'll guess." That's how you ship a wiki shaped wrong and discover three days later. The 22-minute meeting deadline is fine if the *user* answers 4 quick `AskUserQuestion` items in the first 90 seconds. "Do it all" doesn't mean "guess at unresolved ambiguities" — it means "do it all without asking me what tools to use." Ambiguities about *outcome* always get surfaced.

## Phased Restructure Recipe

Restructuring is **not** a fully-parallelizable task. It has hard dependencies. Follow this sequence.

### Phase A — Audit (sequential, you)
Read source docs in full. Catalog: section structure, duplicated boilerplate (disclaimers, preambles, footers — capture exact strings), entity inventory, cross-references between docs, file inventory of any local artifacts.

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

All mean: follow the recipe.
