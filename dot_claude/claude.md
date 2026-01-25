# Claude Configuration

Last verified: 2026-01-18

## About Bojan

- Name: Bojan Rajkovic
- Role: Sr. Director of Software Engineering for Monitoring at SimpliSafe
- I'm not going to talk to you much about work, though -- I'll ask you for
  research for things, coding projects for my homelab or other things,
  journaling and todos, analytical work, etc.

## Directory Structure

- **~/Code**: Code projects -- my homelab configuration, small projects I've
  built, etc.
- **~/Downloads**: Stuff I've downloaded

## Working Directories

- **~/Working/memories**: Things to remember long-term. Memories should be named
  in an entry-specific way. This is a place for long-term documentation -- think
  of it as a personal wiki.
- **~/Working/journal**: Journal entries related to work -- more of a "what
  happened" than a long-term memory. Each file in here corresponds to a day, and
  multiple journal entries in a day should all go into the same file.
  - Unless specified, journal entries should be considered to be for today's date.
- **~/Working/ideas**: Future ideas or things I'm noodling on.
- **~/Working/projects**: Projects I'm working on, with one folder per project,
  full of markdown files.

For all of these things (memories, journals, ideas, todos, projects, etc.), you
should create Markdown documents, and include a small YAML frontmatter section
following this template:

```yaml
---
date: 2025-12-27
category: memory|journal|idea|project|research
project: project-name  # optional, omit if not project-related
labels:
  - label1
  - label2
---
```

**Frontmatter Guidelines:**
- `date`: ISO 8601 format (YYYY-MM-DD), defaults to today's date unless specified
- `category`: One of: memory, journal, idea, project, research
- `project`: Optional, only for project-related content. Use lowercase with hyphens (e.g., "home-assistant")
- `labels`: Optional list of tags. Ask user for labels - they'll provide comma-separated list or decline. Use lowercase, hyphenated multi-word labels (e.g., "home-automation", "kubernetes")

Use these attributes to help you search.

## When to Use Memories, Ideas, and Journals

To help organize information effectively, follow these guidelines:

**Use ~/Working/memories/ when:**
- Documenting technical solutions or troubleshooting steps to remember long-term
- Creating reference documentation for tools, configurations, or processes
- Recording important decisions and their rationale
- Building a personal wiki of reusable knowledge
- Name files descriptively (e.g., "kubernetes-dns-troubleshooting.md")

**Use ~/Working/ideas/ when:**
- Capturing future project ideas or features to explore
- Brainstorming solutions before committing to implementation
- Noting interesting concepts to investigate later
- Recording "what if" scenarios or experimental thoughts

**Use ~/Working/journal/ when:**
- Documenting what happened during a day (events, conversations, progress)
- Recording time-sensitive context that's useful short-term
- Tracking daily work or personal activities
- Files named by date: YYYY-MM-DD.md, multiple entries per day go in same file
- Each entry within a day should use `## HH:MM - Title` format for timestamps

**Use ~/Working/projects/ when:**
- See "Project Management" section below for full workflow

## Instructions and Projects

You should always search the working directories above to see if there's
anything relevant to our current conversation.

**Project Management:**
- ALWAYS check `~/Working/projects/INDEX.yaml` before creating new projects
- When creating a new project:
  1. Check INDEX.yaml to avoid duplicates
  2. Create directory: `~/Working/projects/<project-name>/`
  3. Add entry to INDEX.yaml with metadata
  4. Create README.md in project directory with frontmatter
- When updating a project:
  1. Update the `updated` field in INDEX.yaml
  2. Append important information to project files
- Projects have multiple documents; search entire project directory for context
- Look for PDFs, images, or other files that might contain relevant information

As I do work/converse with you, append important information to the project
files to help you remember. You should prefer to write things in Markdown.

## Search Behavior

- Always search the working directories outlined above for context before
  starting work on a task.
- Check `~/Working/projects/INDEX.yaml` first for quick project lookup
- Use Grep tools across directories to find relevant context in files
- For finding specific files by name/pattern, use Glob tool
- For syntax-aware code searches, use ast-grep (`sg`) when available

## Code Projects

Most of my projects will be either TypeScript (using pnpm and the latest Node LTS) or
Go. Examine the project files in each directory to determine the correct
commands to run to test things. Go projects will often use a Makefile, while
TypeScript/Node projects will use package.json scripts.

If you aren't sure about what to use, examine the repo structure and try to find
the best tools by reading GitHub Actions workflows or examining installed
dependencies.

You run in an environment where ast-grep (`sg`) is available. For searches
requiring structural matching over code, default to `sg --lang <language> -p '<pattern>'`.
Plain-text tools like `rg` miss renamed variables and formatting differences that
ast-grep catches. Use plain-text search only when explicitly requested or when
searching non-code content.

If LSP or Serena skills are available in a project, you MUST use those to search for references to a specific symbol in the code, rather than using plain-text Search tools that are not symbol-aware.

## Research & Documentation Workflow

**When conducting research:**
- Use WebSearch for current information, recent updates, or general knowledge queries
- Use MCP tools for library-specific documentation:
  - Context7: For library API docs and code examples
  - GitHub MCP: For repository documentation and code search
  - Perplexity: For complex research requiring reasoning or deep analysis
- Save research outputs:
  - Short-term/project-specific: Add to project files in `~/Working/projects/<project-name>/`
  - Long-term reference: Create memory in `~/Working/memories/`
  - Exploratory: Capture as idea in `~/Working/ideas/`

## Task Management

**Two separate todo systems:**

1. **Session-based engineering tasks** (TodoWrite/TodoRead tools):
   - Use for multi-step engineering work within a coding session
   - Tracks implementation progress, test runs, fixes
   - Automatically managed per-session
   - Can optionally save alongside projects in `~/Working/projects/<project-name>/`

2. **Personal life todos** (`/tdl` slash command):
   - Use for personal tasks, homelab work, household items
   - Stored in `~/Working/todo/todos.yaml`
   - Rich metadata: priority, due dates, project tags, status tracking
   - Persistent across all sessions

**General guidelines:**
- Always run lints/tests after code changes
- Search existing context before starting new work
- Check `~/Working/projects/INDEX.yaml` before creating projects
- Update project files with decisions and next steps regularly
- Use the AskUserQuestion tool whenever you have questions for me, instead of presenting me with text options

## Boundaries

- **Safe to modify**: All files in `~/Working/`
- **Ask before modifying**: Files in `~/Code/` (confirm which project)
- **Never modify**: System files, dotfiles outside `~/Code/dotfiles/`
