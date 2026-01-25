---
description: Quick capture of ideas
---

# Idea Capture

This command helps you quickly capture ideas for future exploration.

Ideas are for brainstorming, future projects, features to explore, "what if" scenarios, or interesting concepts to investigate later. Store in `~/Working/ideas/`.

## File Structure

Each idea is a markdown file with descriptive filename:

```markdown
---
date: 2025-12-27
category: idea
project: home-assistant  # optional, if related to existing project
labels:
  - automation
  - iot
---

# Idea Title

## The Concept

Brief description of the idea...

## Why This Could Be Useful

Potential benefits or use cases...

## Next Steps (if/when pursued)

- [ ] Research X
- [ ] Prototype Y
- [ ] Evaluate Z

## Related Ideas or Projects

Links to related ideas, memories, or projects...
```

**Frontmatter rules:**
- `date`: ISO 8601 (YYYY-MM-DD), when idea was captured
- `category`: Always "idea"
- `project`: Optional, if related to existing project
- `labels`: Use AskUserQuestion to get labels from user

**Filename conventions:**
- Use descriptive names: `automated-presence-detection.md`
- Lowercase with hyphens
- Make it clear what the idea is about

## Usage

- `/idea <brief description>` - Quick capture of new idea
  - Use AskUserQuestion to ask for labels
  - Use AskUserQuestion to ask for project association (if any)
  - Create file with frontmatter and basic structure
  - User can flesh out details later or you can help expand

- `/idea list [query]` - List existing ideas
  - Search filenames and content with optional query filter
  - Show ideas grouped by project (if applicable)
  - Include date, labels, and brief excerpt
  - Show file paths for navigation

- `/idea expand <filename or description>` - Expand on existing idea
  - Find by filename or search for topic
  - Add more details, research findings, or next steps
  - Keep idea file updated as thinking evolves

## Behavior

- Quick capture is key - don't overthink it
- Ideas can be rough and unpolished
- Cross-reference with related ideas, memories, or projects
- When idea becomes actionable:
  - Suggest creating project in `~/Working/projects/`
  - Suggest adding todo in `/tdl`
  - Keep original idea file as reference
