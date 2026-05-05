---
name: reading-recommendations
description: Use when managing the reading list in Outline — adds books, marks reads, updates taste anchors, and recommends what to read next
---

# Reading Recommendations

All book data lives in Outline. Never create or edit local files for this collection.

## When to Use

**Use for:** adding a book, marking a book read, updating the taste profile, asking "what should I read next?", searching for a specific entry.

**Do not use for:** general book discussion, recommendations not being added to the list, or any file-system operations on `~/Working/projects/reading-recommendations/` (those files are stale after the Outline migration).

## Outline Structure

| What | ID |
|---|---|
| Resources collection | `ab5099b4-17a3-49e6-9b0c-b9792435a2d3` |
| Reading Recommendations parent doc | `0f17b8f8-2138-4fe6-89a5-90ba884b5386` |
| Reader Profile doc | `9156dbab-e59a-4d68-ac97-210cdb4931af` |

Each book is a child document of the Reading Recommendations parent. The parent doc's child list is the index — there is no separate index file to maintain.

## Book Document Format

**Title format:** `"LastName — Title (Year)"` — e.g. `Powers — Declare (2001)`

**Content structure** (no YAML frontmatter — Outline stores title separately):

```markdown
**Author:** Tim Powers  **Year:** 2001  **Status:** to-read  **Priority:** must-try  **Length:** long

**Genres:** weird-horror · cosmic-horror · spy-tradecraft
**Taste anchors:** le-carre · stross-laundry · stephenson-baroque-cycle
**Recommended by:** curation  **Series:** —  **Top pick:** yes

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

**Existing books migrated from local files** may not have the metadata block at the top — the YAML frontmatter was stripped during migration. When updating an existing book, add the metadata block if absent.

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
   - `title`: `"LastName — Title (Year)"`
   - `text`: content (no H1 heading)
   - `parentDocumentId`: `0f17b8f8-2138-4fe6-89a5-90ba884b5386`
   - `collectionId`: `ab5099b4-17a3-49e6-9b0c-b9792435a2d3`
4. If the book introduces a new taste anchor slug, add it to the Reader Profile (see Update taste anchors)

### Mark a book as read

Two touches — both are required for every finished read.

**Touch 1 — Update the book doc:**
1. Search for the doc, save its `id`
2. Fetch the current content: `mcp__claude_ai_Outline__fetch` on the doc URL
3. `mcp__claude_ai_Outline__update_document` with the full updated content:
   - Add the metadata block at the top if absent (fill Status, Priority, etc. from context)
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

**Note:** The `"Status: to-read"` search relies on Outline full-text matching the inline metadata block. Existing migrated books may not have it. If search returns few results, tell the user and offer to load all ~148 docs for a comprehensive pass (slower).

---

## Common Mistakes

| Mistake | Correct behaviour |
|---|---|
| Using `list_collection_documents` | Use `list_documents` with `collectionId` — the other tool doesn't exist |
| Skipping Touch 2 when marking as read | Touch 2 is always required — every read gets a Confirmed Reading History entry |
| Inventing a taste anchor slug | Fetch the Reader Profile and use the Taste Anchor Slugs table; add new ones explicitly |
| Calling `update_document` with a title or URL | Save the `id` from the search result and pass that |
| Editing local files in `~/Working/projects/reading-recommendations/` | Those are stale — Outline is the source of truth |
