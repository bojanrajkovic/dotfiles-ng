# Claude Configuration

Last verified: 2026-05-05

## About Bojan

- Name: Bojan Rajkovic
- Email: brajkovic@coderinserepeat.com
- Role: Sr. Director of Software Engineering for Monitoring at SimpliSafe
- I'm not going to talk to you much about work, though -- I'll ask you for
  research for things, coding projects for my homelab or other things,
  journaling and todos, analytical work, etc.

## Directory Structure

- **~/Code**: Code projects -- my homelab configuration, small projects I've
  built, etc.
- **~/Downloads**: Stuff I've downloaded

## Working Directories

- **~/Working/todo**: Personal todo list (managed via `/tdl` slash command).
- **~/Working/projects**: Local artifacts only — code, data, config files, and
  HTML artifacts for active projects. Project *documentation* lives in Outline
  (see Project Management below).

**Memories, Journal, and Ideas now live in Outline.** Do not create local files
for any of these — use Outline MCP tools instead:
- Memories + Journal → Personal collection (`ace54f9c-91d2-4d17-bf17-f503e63326c0`, private)
- Ideas → Resources collection (`ab5099b4-17a3-49e6-9b0c-b9792435a2d3`), under the "Ideas" parent doc

## When to Use Memories, Ideas, and Journals

**Use Outline Personal collection (`ace54f9c-91d2-4d17-bf17-f503e63326c0`) for memories when:**
- Documenting technical solutions or troubleshooting steps to remember long-term
- Creating reference documentation for tools, configurations, or processes
- Recording important decisions and their rationale
- Building a personal wiki of reusable knowledge
- Use `mcp__claude_ai_Outline__create_document` with the Personal collection ID
- Use descriptive titles (e.g., "Kubernetes DNS Troubleshooting")

**Use Outline Resources collection for ideas when:**
- Capturing future project ideas or features to explore
- Brainstorming solutions before committing to implementation
- Noting interesting concepts to investigate later
- Recording "what if" scenarios or experimental thoughts
- Create as a child doc under the "Ideas" parent doc in Resources
- Ideas may eventually be promoted to the Projects collection

**Use Outline Personal collection for journal when:**
- Documenting what happened during a day (events, conversations, progress)
- Recording time-sensitive context that's useful short-term
- Tracking daily work or personal activities
- Structure: Personal collection → "Journal" parent doc → YYYY-MM-DD child doc → `##` sections per topic
- Each date doc title: `YYYY-MM-DD`; topic entries are `##` headings within the doc

## Instructions and Projects

You should always search Outline and local working directories for anything
relevant to the current conversation before starting work.

**Project Management:**

Projects have two layers:
1. **Documentation** (research notes, design docs, planning) → **Outline Projects collection** (`cdabb3c3-c49b-4089-98e5-25e4a094aa0c`)
2. **Local artifacts** (code, data files, configs, scripts, HTML) → `~/Working/projects/<project-name>/` or `~/Projects/<project-name>/`

**Finding existing projects:**
- ALWAYS call `mcp__claude_ai_Outline__list_collection_documents` on the Projects collection before creating anything new
- For code-adjacent projects, also check `~/Working/projects/PROJECTS.yaml` for the local path

**Creating a new project:**
1. Call `mcp__claude_ai_Outline__list_collection_documents` to confirm it doesn't exist
2. Create a parent doc in the Projects collection with `mcp__claude_ai_Outline__create_document`
3. If the project has local code/data, create `~/Working/projects/<name>/` for those artifacts only
4. If the project has a code repo at `~/Projects/<name>/`, add an entry to `~/Working/projects/PROJECTS.yaml`

**Updating a project:**
1. Find the project doc in Outline (search or list collection)
2. Update it with `mcp__claude_ai_Outline__update_document`
3. For local artifacts, write/update local files as before

**PROJECTS.yaml** (`~/Working/projects/PROJECTS.yaml`) — thin pointer index for
projects with significant local code repos. Format:

```yaml
- name: atc
  outline_id: <parent-doc-id>
  local_path: ~/Projects/atc

- name: nacha-visualizer
  outline_id: <parent-doc-id>
  local_path: ~/Projects/nacha-visualizer
```

Pure-doc projects (no code repo) don't need an entry here.

As work progresses, append notes and decisions to the relevant Outline docs.

## Search Behavior

- **For project docs, memories, journal**: Use `mcp__claude_ai_Outline__list_documents` with a query
  - Projects collection: `cdabb3c3-c49b-4089-98e5-25e4a094aa0c`
  - Personal collection: `ace54f9c-91d2-4d17-bf17-f503e63326c0` (memories + journal)
  - Resources collection: `ab5099b4-17a3-49e6-9b0c-b9792435a2d3` (reading recommendations)
- **For local code/configs/data**: Use grep/glob/ast-grep on `~/Working/projects/` or `~/Projects/`
- Check `~/Working/projects/PROJECTS.yaml` when you need to connect a project name to a local code path or Outline doc ID

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
  - Project-specific: Add to the project's Outline doc (or a child doc) via `mcp__claude_ai_Outline__update_document` / `mcp__claude_ai_Outline__create_document`
  - Long-term reference: Create a memory doc in the Outline Personal collection
  - Exploratory: Capture as child doc under "Ideas" in the Outline Resources collection

## Task Management

**Two separate todo systems:**

1. **Session-based engineering tasks** (TodoWrite/TodoRead tools):
   - Use for multi-step engineering work within a coding session
   - Tracks implementation progress, test runs, fixes
   - Automatically managed per-session

2. **Personal life todos** (`/tdl` slash command):
   - Use for personal tasks, homelab work, household items
   - Stored in `~/Working/todo/todos.yaml`
   - Rich metadata: priority, due dates, project tags, status tracking
   - Persistent across all sessions

**General guidelines:**
- Always run lints/tests after code changes
- Search Outline and local context before starting new work
- Check Outline Projects collection before creating projects
- Update Outline project docs with decisions and next steps regularly
- Use the AskUserQuestion tool whenever you have questions for me, instead of presenting me with text options

## Boundaries

- **Safe to modify**: All files in `~/Working/` (excluding memories/journal which are now in Outline)
- **Ask before modifying**: Files in `~/Code/` or `~/Projects/` (confirm which project)
- **Never modify**: System files, dotfiles outside `~/Code/dotfiles/`
