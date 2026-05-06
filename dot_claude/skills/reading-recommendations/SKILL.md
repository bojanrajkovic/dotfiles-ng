---
name: reading-recommendations
description: Use when managing the reading list in Outline — adds books, marks reads, updates taste anchors, and recommends what to read next
---

# Reading Recommendations

All book data lives in Outline. Never create or edit local files for this collection.

## When to Use

**Use for:** adding a book, marking a book read, updating the taste profile, asking "what should I read next?", searching for a specific entry.

**Do not use for:** general book discussion, recommendations not being added to the list, or any file-system operations on `~/Working/projects/reading-recommendations/` (those files are deleted after the Outline migration).

## Outline Structure

| What | ID |
|---|---|
| Resources collection | `ab5099b4-17a3-49e6-9b0c-b9792435a2d3` |
| Reading Recommendations parent doc | `0f17b8f8-2138-4fe6-89a5-90ba884b5386` |
| **Books** (intermediate parent — all book docs live here) | `639b1aee-b922-4592-81c7-6c92c90266a5` |
| Reader Profile doc | `9156dbab-e59a-4d68-ac97-210cdb4931af` |

Hierarchy: **Resources → Reading Recommendations → Books → individual book docs**

The Books doc's child list is the index — there is no separate index file to maintain.

## Book Document Format

**Title format:** Just the book title — e.g. `Declare`, `Tomorrow, and Tomorrow, and Tomorrow`. Do NOT prefix with author or year. If two books genuinely share a title, append `(Year)` to disambiguate.

**Content structure** — starts with a two-column metadata table (no header row), then `##` sections:

```markdown
|  |  |
|---|---|
| **Author** | Tim Powers |
| **Year** | 2001 |
| **Status** | to-read |
| **Priority** | must-try |
| **Length** | long |
| **Top pick** | yes |
| **Rating** | — |
| **Date read** | — |
| **Reread** | no |
| **Genres** | weird-horror · spy-tradecraft |
| **Taste anchors** | le-carre · stross-laundry |
| **Recommended by** | curation |
| **Series** | — |

## Pitch
[Why this book fits this specific taste profile]

## Why it fits
[Named taste-anchor connections]

## Caveats
[Honest warnings — pacing, register, length, content]

## Links
- [Find on Amazon](...)

## Review

*To be filled in after reading.*

- **Rating:**
- **What resonated:**
- **What didn't:**
- **Reread likelihood:**
- **Would recommend to:**

## Notes
[Post-read annotations, quotes, threads to pull on]
```

**Controlled vocabularies** — use exactly these values:

| Field | Values |
|---|---|
| Status | `to-read` · `reading` · `read` · `abandoned` · `skipped` |
| Priority | `must-try` · `strongly-recommended` · `worth-considering` |
| Length | `short` (<200pp) · `medium` (200–500pp) · `long` (500–1000pp) · `epic` (>1000pp) |
| Recommended by | `curation` · `wife` · `friend` · `self` · `other` |

**Taste anchor slugs** — ALWAYS fetch the Reader Profile (`9156dbab`) and check the Taste Anchor Slugs table before using any slug. Never invent a slug; add new ones to the table when warranted.

**Existing migrated books** may not all have the metadata table yet. When updating an existing book, add the table if absent.

---

## Workflows

### Search for a book (do this before any add or update)

```
mcp__claude_ai_Outline__list_documents(
  query="<author or title>",
  collectionId="ab5099b4-17a3-49e6-9b0c-b9792435a2d3"
)
```

Save the `id` field from the result — you need it for `update_document`.

### Add a new book

1. Search first (above) to confirm no duplicate exists
2. Compose content following the Book Document Format above
3. `mcp__claude_ai_Outline__create_document`:
   - `title`: just the book title
   - `text`: content starting with the metadata table (no H1 heading)
   - `parentDocumentId`: `639b1aee-b922-4592-81c7-6c92c90266a5` ← **Books doc, not Reading Recommendations**
   - `collectionId`: `ab5099b4-17a3-49e6-9b0c-b9792435a2d3`
4. If the book introduces a new taste anchor slug, add it to the Reader Profile (see Update taste anchors)

### Mark a book as read

Two touches — both are required for every finished read.

**Touch 1 — Update the book doc:**
1. Search for the doc, save its `id`
2. Fetch the current content: `mcp__claude_ai_Outline__fetch` on the doc URL
3. `mcp__claude_ai_Outline__update_document` with the full updated content:
   - Add the metadata table at the top if absent
   - Set `**Status:** read`
   - Set `**Rating:** N` (1–5)
   - Fill the Review section — rating, what resonated, what didn't, reread likelihood
   - Add notable quotes or threads to Notes

**Touch 2 — Update the Reader Profile (always required for finished reads):**
1. Fetch Reader Profile: `mcp__claude_ai_Outline__fetch` on `9156dbab-e59a-4d68-ac97-210cdb4931af`
2. Add the book to "Confirmed Reading History" under the appropriate cluster with a one-line reaction summary
3. If the reaction was unexpected or the book opens a new taste direction: also update Signal Interpretation Rules and/or add a new slug to the Taste Anchor Slugs table
4. `mcp__claude_ai_Outline__update_document` on the Reader Profile (`9156dbab-e59a-4d68-ac97-210cdb4931af`)

Touch 2 is not optional — every finished read gets an entry in Confirmed Reading History.

### Update taste anchors (standalone recalibration)

1. Fetch the Reader Profile: `mcp__claude_ai_Outline__fetch` on `9156dbab-e59a-4d68-ac97-210cdb4931af`
2. Find recently-read books: search `mcp__claude_ai_Outline__list_documents` with query `"Status: read"` and `collectionId="ab5099b4-17a3-49e6-9b0c-b9792435a2d3"`
3. Fetch each relevant book doc and extract Review + Notes content
4. Update the Reader Profile:
   - Amend Confirmed Reading History for any missing entries
   - Update Signal Interpretation Rules where reactions revealed new or changed signals
   - Add new slugs to Taste Anchor Slugs table if warranted
5. `mcp__claude_ai_Outline__update_document` on the Reader Profile

### "What should I read next?"

1. Fetch the Reader Profile to load current taste signals and Category Priority order
2. Search for unread candidates: `list_documents(query="Status: to-read", collectionId="ab5099b4...")`
   - If results are sparse, also try `query="Status: to-read priority: must-try"`
3. From the results, identify the 8–12 strongest title/author matches against the taste signals
4. Fetch those candidate docs in full to read Pitch, Why it fits, Caveats, and taste anchors
5. Rank using the Category Priority from the Reader Profile:
   1. Weird/cosmic horror (highest)
   2. Hard-SF with dread or existential horror
   3. Historical intrigue with weird/uncanny elements
   4. Spy/tradecraft (only the best net-new)
6. Present top 3–5 picks — one paragraph per book, citing specific taste anchors and why this book over others

**Note:** The `"Status: to-read"` search relies on Outline full-text matching the inline metadata table. Existing migrated books may not have it yet. If search returns few results, tell the user and offer to load all ~150 docs for a comprehensive pass (slower).

### Cross-link book mentions

When the Reader Profile or a book doc names another book in the collection, that mention should hyperlink to the target. Follow this pattern when adding a book that references existing entries, or when retroactively linking older docs.

1. Build the title→URL map: `list_collection_documents` on `ab5099b4-17a3-49e6-9b0c-b9792435a2d3`, then filter children of the Books doc (`639b1aee`).
2. Fetch the doc you're about to edit and copy its current body.
3. For each mention of another collection title, rewrite as a markdown link, dropping italic wrappers:
   - `*Title*` → `[Title](url)` (strip the `*`)
   - `**Title**` → `[**Title**](url)` (keep the bold)
   - Plain `Title` → `[Title](url)`
4. Never self-link — skip the doc's own title.
5. Match whole titles case-insensitively. Watch for false positives ("Contact" inside "first-contact" should not match).
6. Apply ALL substitutions in a single `update_document` call with `editMode: "replace"`. See "Outline editing gotchas" below for why this matters.

---

## Outline editing gotchas

Non-obvious `update_document` behaviors discovered during heavy migration and link-backfill work. Apply on every edit.

- **An open browser tab on the doc will silently overwrite your API writes.** Outline is a real-time collaborative editor: a browser tab holds a ProseMirror state of the doc, and any sync/focus/keystroke event pushes that state back to the server. If you `update_document` while a tab is open, the tab's stale state will land seconds-to-minutes later as a new revision and clobber your changes — without errors. **Before any non-trivial edit, ask the user to close the browser tab on the target doc.** This is the single most important rule, and explains 90% of "my links disappeared" mysteries.
- **`patch` mode silently strips hyperlinks.** Calls return success and the revision increments, but Outline's ProseMirror engine drops the link during render. **Always use `editMode: "replace"` when adding links to existing text.** Trade-off: replace needs the full body, so fetch first.
- **Multi-pass `replace` calls overwrite each other.** A second `replace` composed from a stale fetch will silently undo the first pass's changes. **For multiple substitutions in one doc, compose them all into a single `replace`.**
- **`create_attachment` is broken** — fails with `Cannot read properties of undefined (reading 'get')` (server-side MCP bug). Migrate file content (transcripts, notes) as child Outline docs instead of attaching binaries.
- **Hyperlinks inside completed task list items don't persist** — ProseMirror limitation. Links wrapped in `- [x]` checked items are silently dropped.
- **Document body must not start with an H1.** Title is a separate field; begin with body text or a `##` heading.
- **Don't trust an agent's "links added" self-report.** Subagents echo back what they sent in the update payload, which is not the same as what Outline rendered. Always re-fetch the doc and inspect.

---

## Common Mistakes

| Mistake | Correct behaviour |
|---|---|
| Titling a book doc as "Author — Title (Year)" | Title is just the book title; author and year go in the metadata table |
| Using inline bold text for metadata (`**Author:** X  **Year:** Y`) | Use the two-column markdown table format — see Book Document Format above |
| Parenting new books under Reading Recommendations (`0f17b8f8`) | Parent under **Books** (`639b1aee`) — that's one level deeper |
| Skipping Touch 2 when marking as read | Touch 2 is always required — every read gets a Confirmed Reading History entry |
| Inventing a taste anchor slug | Fetch the Reader Profile and use the Taste Anchor Slugs table; add new ones explicitly |
| Calling `update_document` with a title or URL | Save the `id` from the search result and pass that |
| Editing local files in `~/Working/projects/reading-recommendations/` | Those files are deleted — Outline is the only source of truth |
| Editing a doc while the user has it open in a browser tab | Ask the user to close the tab first — the tab's stale ProseMirror state will silently overwrite the API write |
| Using `editMode: "patch"` to add hyperlinks | Use `"replace"` — patch silently drops links during ProseMirror render |
| Doing multiple `replace` updates per doc in sequence | Compose all substitutions into one `replace` — sequential calls overwrite each other |
| Trusting an agent's "links added" report without verifying | Re-fetch the doc to inspect — the update response echoes what was sent, not what persisted |
| Calling `create_attachment` to upload a binary | Tool is broken; migrate file content as a child Outline doc instead |
