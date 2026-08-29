---
description: Create or update daily journal entries
---

# Journal Entry Manager

This command creates or updates daily journal entries in Outline (see `@OUTLINE.md`), not local
files. Each day is one document, titled `YYYY-MM-DD`, nested under the "Journal" parent document
(`e171d930-2453-491a-af65-6cb2ed4f1baa`) in the Personal collection
(`ace54f9c-91d2-4d17-bf17-f503e63326c0`).

Journal entries capture what happened during a day - events, conversations, progress on tasks,
observations. Think of it as a daily log rather than permanent documentation.

## Document structure

No frontmatter — the date is the document title. Multiple timestamped sections per day:

```markdown
## 09:30 - Morning standup

Notes from standup...

## 14:00 - Debugging homelab issue

Found the problem with...

## 16:30 - End of day thoughts

Made progress on...
```

**Entry format:**
- Use `## HH:MM - Title` for each timestamped entry
- Multiple entries in one document for the same day
- Append new entries to the existing document for today

## Usage

- `/journal` - Create/update today's journal entry
- `/journal some thoughts` - Add content to today's journal
- `/journal 2024-03-15 specific date entry` - Create/update entry for a specific date

## Behavior

- List children of the Journal parent doc (`list_collection_documents` on the Personal collection,
  or `list_documents` filtered to that collection) to check whether a document titled with the
  target date already exists.
- If it exists: `update_document` with `editMode: "append"`, adding a new `## HH:MM - Title`
  section.
- If it doesn't exist: `create_document` with `parentDocumentId` set to the Journal doc,
  `collectionId` set to Personal, `title` as the date, and `text` starting with the first
  `## HH:MM - Title` section.
- Default to today's date unless a specific date is provided.
