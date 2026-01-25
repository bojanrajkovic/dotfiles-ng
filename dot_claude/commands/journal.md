---
description: Create or update daily journal entries
---

# Journal Entry Manager

This command helps you create or update daily journal entries. Each entry is stored as a markdown file in `~/Working/journal/` with the naming convention: YYYY-MM-DD.md

Journal entries capture what happened during a day - events, conversations, progress on tasks, observations. Think of it as a daily log rather than permanent documentation.

## File Structure

Each journal file should have frontmatter and timestamped entries:

```markdown
---
date: 2025-12-27
category: journal
labels:
  - optional-labels
---

## 09:30 - Morning standup

Notes from standup...

## 14:00 - Debugging homelab issue

Found the problem with...

## 16:30 - End of day thoughts

Made progress on...
```

**Frontmatter rules:**
- `date`: ISO 8601 (YYYY-MM-DD), matches filename
- `category`: Always "journal"
- `labels`: Optional, ask user if they want labels for this entry

**Entry format:**
- Use `## HH:MM - Title` for each timestamped entry
- Multiple entries in one file for same day
- Append new entries to existing file for today

## Usage

- `/journal` - Create/update today's journal entry
- `/journal some thoughts` - Add content to today's journal
- `/journal 2024-03-15 specific date entry` - Create/update entry for a specific date

## Behavior

- If file exists for the date: append new entry with current timestamp
- If file doesn't exist: create with frontmatter and first entry
- Use AskUserQuestion to ask for labels on file creation (not on appends)
- Default to today's date unless specific date provided
