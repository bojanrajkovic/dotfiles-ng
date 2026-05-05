---
name: reading-recommendations
description: Manage the reading recommendations collection in Outline — add books, mark as read, update taste anchors, and recommend what to read next
---

# Reading Recommendations

Manages the reading list and taste profile in Outline. All book data lives in Outline — do not create or edit local files.

## Outline Structure

| What | ID |
|---|---|
| Resources collection | `ab5099b4-17a3-49e6-9b0c-b9792435a2d3` |
| Reading Recommendations parent doc | `0f17b8f8-2138-4fe6-89a5-90ba884b5386` |
| Reader Profile doc | `9156dbab-e59a-4d68-ac97-210cdb4931af` |

Each book is a **child document** of the Reading Recommendations parent. There is no other index to maintain — Outline's search and the parent doc's child list are the index.

## Book Document Format

Every book doc has this structure. **Title** = `"Author Last Name — Title (Year)"` format (e.g. `Powers — Declare (2001)`).

Content starts with a metadata block, then fixed sections:

```markdown
**Author:** Tim Powers  **Year:** 2001  **Status:** to-read  **Priority:** must-try  **Length:** long

**Genres:** weird-horror · cosmic-horror · spy-tradecraft  
**Taste anchors:** le-carre · stross-laundry · stephenson-baroque-cycle  
**Recommended by:** curation  **Series:** —  **Top pick:** yes

## Pitch
[Why this book; what it does well for this taste profile]

## Why it fits
[Specific taste-anchor connections]

## Caveats
[Honest warnings — pacing, content, length]

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

**Status values:** `to-read` | `reading` | `read` | `abandoned` | `skipped`  
**Priority values:** `must-try` | `strongly-recommended` | `worth-considering`  
**Length values:** `short` (<200pp) | `medium` (200–500pp) | `long` (500–1000pp) | `epic` (>1000pp)

**Taste anchor slugs** are defined in the Reader Profile doc. Always use slugs from that controlled vocabulary — do not invent new ones without also adding them to the Reader Profile.

---

## Workflows

### Add a new book recommendation

1. Compose the book doc content following the format above
2. Call `mcp__claude_ai_Outline__create_document` with:
   - `parentDocumentId`: `0f17b8f8-2138-4fe6-89a5-90ba884b5386`
   - `collectionId`: `ab5099b4-17a3-49e6-9b0c-b9792435a2d3`
   - `title`: `"LastName — Title (Year)"`
   - `text`: content without H1
3. If the book introduces a new taste anchor, add it to the Reader Profile doc (see below)

**Do not** create duplicate entries — search first:
```
mcp__claude_ai_Outline__list_documents(query="<title or author>", collectionId="ab5099b4...")
```

### Mark a book as read

Two touches are required:

**Touch 1 — Update the book doc:**
1. Search for the doc: `list_documents(query="<title>", collectionId="ab5099b4...")`
2. Call `mcp__claude_ai_Outline__update_document` to:
   - Change `**Status:** to-read` → `**Status:** read`
   - Set `**Rating:** N`
   - Fill in the Review section with reactions, what resonated, what didn't, reread likelihood
   - Add any notable quotes or threads to Notes

**Touch 2 — Update the Reader Profile if the book shifts the signals:**
- Open `mcp__claude_ai_Outline__fetch` on the Reader Profile doc (`9156dbab-e59a-4d68-ac97-210cdb4931af`)
- Add the book to "Confirmed Reading History" under the appropriate cluster
- If a new taste anchor slug is warranted, add it to the Taste Anchor Slugs table at the bottom
- Call `mcp__claude_ai_Outline__update_document` on the Reader Profile

Touch 2 is only needed if the read meaningfully shifts the taste signals (strong reaction, new anchor, recalibration). Routine reads that land where expected don't require a profile update.

### Update taste anchors (standalone)

When asked to update the taste profile based on accumulated reads or a recalibration:

1. Fetch the Reader Profile: `mcp__claude_ai_Outline__fetch` on `9156dbab-e59a-4d68-ac97-210cdb4931af`
2. Search for recently-read books: `list_documents(query="status: read", collectionId="ab5099b4...")`
3. Read each relevant book doc to extract reactions and anchor connections
4. Update the Reader Profile: amend Confirmed Reading History, Signal Interpretation Rules, and Taste Anchor Slugs table as warranted
5. Call `mcp__claude_ai_Outline__update_document` on the Reader Profile doc

### "What should I read next?"

1. Fetch the Reader Profile to load the current taste signals
2. Call `mcp__claude_ai_Outline__list_collection_documents` on the parent (`0f17b8f8...`) to get all book doc IDs — this returns titles, which encode author + status
3. Filter mentally for `to-read` and `must-try` / `strongly-recommended` based on title metadata visible in the list
4. Fetch the 5–10 strongest candidate docs in full to read their Pitch, Why it fits, and taste_anchors
5. Rank against the current taste signals from the Reader Profile (prioritise Category Priority order: weird/cosmic horror → hard-SF with dread → historical intrigue with uncanny elements → spy/tradecraft)
6. Present top 3–5 picks with a one-paragraph rationale each, citing specific taste anchors

**Efficiency tip:** The title format `"Author — Title (Year)"` doesn't carry status. If you need to filter by status efficiently, search for specific terms that appear in read vs. unread docs, or ask the user if they want you to load all ~148 docs (slower but comprehensive).

### Search for a specific book

```
mcp__claude_ai_Outline__list_documents(query="<author or title>", collectionId="ab5099b4-17a3-49e6-9b0c-b9792435a2d3")
```

---

## Key taste signals (quick reference)

Load the Reader Profile for full detail. The short version:

- **Top priority:** weird/cosmic horror with a plot spine (not pure mood)
- **Institutional density** is the through-line — Bene Gesserit, the Laundry, the Circus, Merchant Princes statecraft
- **Investigative spine required** — mole hunt, dossier, expedition, dynastic mystery underneath dreamlike prose
- **Disease/pandemic/bioterror** is a confirmed hit
- **Religious and mythological fiction** is a confirmed bet
- **Wife's picks** (`recommended_by: wife`) stretch toward family sagas and contemporary literary fiction — query separately to isolate core-profile signal
