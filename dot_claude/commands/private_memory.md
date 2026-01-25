---
description: Create or search long-term memories
---

# Memory Manager

Memories are permanent reference documentation: technical solutions, troubleshooting
guides, configuration notes, decision rationale. Store in `~/Working/memories/` as
a personal wiki.

## File Structure

Each memory is a standalone markdown file with descriptive filename:

```markdown
---
date: 2025-12-27
category: memory
project: home-assistant  # optional, if related to a project
labels:
  - kubernetes
  - troubleshooting
  - networking
---

# Title of Memory

Content explaining the concept, solution, or reference information...

## Examples

Code snippets, commands, or examples...

## Related

Links to related memories, projects, or external resources...
```

**Frontmatter rules:**
- `date`: ISO 8601 (YYYY-MM-DD), creation date
- `category`: Always "memory"
- `project`: Optional, link to related project in `~/Working/projects/`
- `labels`: Use AskUserQuestion to get labels from user

**Filename conventions:**
- Use descriptive names: `kubernetes-dns-troubleshooting.md`
- Lowercase with hyphens
- Make it searchable and meaningful

## Usage

- `/memory create <topic>` - Create new memory about a topic
  - Use AskUserQuestion to ask for labels
  - Use AskUserQuestion to ask for project association (if any)
  - Create file with frontmatter and basic structure
  - Open for user to add content

- `/memory search <query>` - Search existing memories
  - Search filenames first (fast)
  - Search file contents with Grep if needed
  - Show matching memories with filename, labels, and relevant excerpt
  - Return file paths for easy navigation

- `/memory update <filename or topic>` - Update existing memory
  - Find by filename or search for topic
  - Append new information or update existing content
  - Update date in frontmatter to today

## Behavior

- Always search before creating to avoid duplicates
- Suggest related memories when creating new ones
- Keep memories focused on one topic/solution per file
- Cross-reference related memories in "Related" section
- Update existing memory rather than creating duplicate
