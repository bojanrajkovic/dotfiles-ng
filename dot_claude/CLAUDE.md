# Claude Configuration

Last verified: 2026-05-09

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

**Scratch files in `/tmp` — always namespace with the current Claude Code session ID.** Pattern: `mkdir -p /tmp/claude-<session-id>/` once per session, then write all scratch files (PR bodies, agent prompts, codex outputs, log captures) under that directory. Bare paths like `/tmp/atc-pr-body.md` are shared across sessions, agents, and rejected prior runs — stale files from any of those will silently collide with new writes. The `Write` tool's "must Read before Write" guard catches some collisions but downstream `Bash` commands can still pick up stale content before the overwrite lands. The session ID is visible in the harness context at session start. Skills that already `mktemp -d` (e.g., `codex-review-plan` → `/tmp/codex-plan-review-XXXXXX`) satisfy this convention.

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

**Wiki-shape (Outline project docs):**

When creating or restructuring docs in Outline, treat them as wiki-flavored, not PDF-flavored:

- **One canonical home per concept.** Caveats, glossary, run metadata live on a single "About" doc; other pages link, never duplicate.
- **Container + leaves.** Parent landing = TL;DR + dashboard + nav. Topical containers (e.g. "Findings by Domain") group leaf pages. Each leaf covers one entity.
- **Cross-link via plain Markdown links** to doc URLs — Outline `@mention` syntax is for users only.
- **No leading H1** in doc body — Outline stores titles separately. Start each doc with the first paragraph or H2.
- **Outline doc revisions are your version history.** No "v2" or "old" docs — open `⋯ → History` per page.
- **Before deleting a doc, grep the rest of the wiki for references** — stale links are silent failures.

**Syncthing-aware path references (`~/Sync/...` projects):**

For projects whose local files live in `~/Sync/` (synced across multiple devices), reference the synced location by share label + folder ID, not by `~/Sync/...` (which is macOS-only on this machine):

```
Synced share:   Home  (Syncthing folder ID: uqppb-cg2dq)
Relative path:  Working/projects/<name>/
```

In file inventories, tag files by replaceability — ✅ regenerable / ❌ irreplaceable — so backup priorities are obvious. Regenerable build artifacts (downloadable databases, generated reports) shouldn't be left in the synced share if they're large.

**Multi-doc subagent fan-out:**

When delegating parallel doc creation (e.g. splitting a monolithic doc into a wiki):

- Create container parents **before** fanning out — children need parent IDs.
- Sibling subagents running in parallel **cannot cross-link to each other** — their URLs aren't known until they return. Defer cross-linking to a final pass after all docs exist.
- Always pass canonical URLs/IDs in subagent prompts. Subagents will fabricate plausible-but-wrong slugs from memory if you don't — this is a real, observed failure mode, not a theoretical one.
- For content migration, give subagents **literal strings to remove**, not pattern descriptions. "Drop any closing footer" misses sibling variants; "drop these exact lines: …" doesn't.
- **Constrain fabrication-prone content claims in the prompt, and verify them after.** A subagent authoring prose will manufacture confident-sounding history — "X was newly released / in beta / the dominant choice at decision time" — whenever the prompt doesn't forbid it. Tell it: do not assert *when* something was released or *how popular* it was unless a primary source supports it; lean on durable comparison points instead. Also tell it not to link to non-repo/external sources it was only given for research. When it returns, skim for "newly", "recently", "beta", "early release", "dominant", "widely adopted" — these survive review unless someone goes looking, so verify or cut each.
- Spot-check the two highest-leverage outputs before declaring done — typically the page with the most cross-links and the page with the densest content. Use a Haiku subagent with an explicit checklist for the rest.

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

**Python — never `pip install` for ad-hoc work.** For one-off scripts and tool invocations, use `uv run --with <package> python -c '...'` (or `uv run --with <package> <command>`). uv provisions an ephemeral env per invocation; bare `pip install` / `pip3 install` mutates the mise-managed Python at `~/.local/share/mise/installs/python/<ver>/` and leaves silent pollution. Long-lived project venvs use `uv venv` + `uv pip install` inside or `pyproject.toml` + `uv sync`. Globally-managed Python CLI tools go through `mise use -g "pip:<pkg>"` — a deliberate decision tracked by mise, not an ad-hoc one. Canonical: [Always use uv run for one-off Python, never pip3 install](https://outline.gaur-kardashev.ts.net/doc/always-use-uv-run-for-one-off-python-never-pip3-install-DOwRtWIECN).

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
- Use the AskUserQuestion tool whenever you have questions for me, instead of presenting me with text options. Surface uncertainty early — from the outside, a long blocking wait (a stuck `kubectl wait`, a slow agent) is indistinguishable from a hang, so ask rather than going quiet.
- **Never put substantive reasoning in the same turn as an AskUserQuestion call.** Text emitted before/between tool calls is not reliably rendered — the question dialog may be all I see of the turn, and long `question` text is truncated by the dialog UI too. End a turn with the reasoning as plain text (no trailing tool call), then immediately ask in the next turn — back-to-back, no pausing to wait for me to acknowledge or say "OK, ask". Self-contained option descriptions are a fallback for short questions only. If I answered a question whose supporting text I never saw, reprint the reasoning and re-confirm rather than acting on the answer.
- After producing a substantial batch of durable work (several Outline docs, a long plan, a multi-PR stretch), pause and offer a review before moving to the next big commitment. An earlier "yes, proceed" doesn't bind through substantial intervening work — give me the chance to revisit the prior artifacts first.

## Commits

**Use atomic commits — one logical, self-contained change per commit.** When implementing a multi-step plan, commit per phase/step (e.g. config, then the shared helper, then the feature, then docs) rather than one giant commit at the end. Each commit should stand on its own: a coherent conventional-commit subject, a body explaining *what shipped and why*, and a working tree that builds with lints and tests green at that commit (the pre-commit/pre-push hooks enforce this). Don't bundle unrelated changes; don't leave a phase half-committed. On squash-merge repos the intra-branch commits collapse into one anyway, but atomic commits keep the branch reviewable while it's open and make `git bisect`/revert sane on merge-commit repos.

## Pull Requests

**Check the repo's merge strategy before writing the PR body.** Use `gh repo view --json mergeCommitAllowed,squashMergeAllowed,rebaseMergeAllowed` or look at recent merged PRs (`gh pr list --state merged --limit 5`) to see which strategy is actually used. Most of my repos squash-merge (95%+ of the time), but verify rather than assume.

**Never put the issue reference (or the issue title) in the PR title.** On squash-merge, GitHub appends the PR number to the squashed commit subject (e.g. `(#144)`), so a title that already ends in `(#141)` produces an ugly double-parenthetical — `refactor(meals): … (#141) (#144)` — in `git log`. Keep the title to the bare conventional-commit subject: no `(#NNN)` suffix, and don't echo the issue title verbatim. Link the issue from the **body** with a `Closes #NNN` line, which auto-closes it on merge and keeps the squashed subject clean.

**On squash-merge repos, the PR body becomes the commit body.** Write the body as "what shipped in this commit" — readable months later by someone running `git log`, not as a PR-style document with `## Summary` / `## Test Plan` markdown sections that look weird inside a commit message. Open with a one-or-two-sentence lead, then bulleted or paragraph detail. No `## Summary` header on the lead — the title is the summary.

Transient verification content (test plans, manual-check checklists, screenshots) goes in a **PR comment** posted after the PR is created, not in the body. The body is for what the change *is*; the comment is for what reviewers need to *do*.

**On merge-commit / rebase repos**, the body is just a PR document, so the conventional `## Summary` / `## Test Plan` structure is fine.

**Don't push directly to `main`** — branch and open a PR (or confirm first); never chain commit + push straight to `main`.

**Stacked PRs + auto-delete-on-merge:** if a repo has `deleteBranchOnMerge=true`, merging a base PR deletes its branch and CLOSES any open dependent PR based on it. Retarget dependents to their eventual base (`gh pr edit <n> --base main`) BEFORE merging the base; `--delete-branch` is moot (the repo deletes regardless). For the Codex review/merge end-game, the `ship-pr` skill is canonical.

## Working style

- **Modularity / locality is my top tie-breaker in structural and layout calls** — weight test-next-to-code and the per-entity/per-module directory (as the unit of change) above other factors, and prefer honest explicit coupling (plain deep `../../` relative imports) over convenience indirection (path aliases) unless the churn is demonstrated.
- I sometimes **ask you to justify a recommendation I already agree with** — pressure-testing the reasoning, not disagreement. Give the honest case plus its soft spots; don't cave or over-defend.
- I **steer away from process ceremony** — once direction is set, execute and lean on strong verification (typecheck / test / build / round-trip) + downstream review, rather than heavy up-front plan gates.
- **File follow-up issues after design completes, not as acceptance criteria.** Out-of-scope concerns surfaced while designing are meta-work with no code deliverable; capture them as a "file after design" note and `gh issue create` them between finishing the design and handing off — never in the ACs.
- **Project docs document what _is_, not the journey** — cut "we tried X", "empirically observed", PR/SHA references, and first-person anecdotes; describe the destination.
- **Subagents:** pass `model: "sonnet"` to `ed3d-plan-and-execute:task-implementor-fast` and `task-bug-fixer` (both default to Haiku, which has produced sham tests / broken fixtures / partial fixes); use `opus` for very large or cross-cutting work. `code-reviewer` already defaults to Opus.
- **Diagrams: reach for them more often — I like diagrams.** Default to including one whenever it clarifies a flow, sequence, state machine, architecture, or data shape, not only when asked. **ASCII in the direct chat interface, Mermaid where it'll render (Outline, GitHub, committed Markdown — ADRs, architecture docs).** The terminal has no Mermaid renderer — a ` ```mermaid ` fence shows as raw source in chat, so draw ASCII (or offer a rendered image) in replies; in rendering surfaces Mermaid is preferred.

## Boundaries

- **Safe to modify**: All files in `~/Working/` (excluding memories/journal which are now in Outline)
- **Ask before modifying**: Files in `~/Code/` or `~/Projects/` (confirm which project)
- **Never modify**: System files, dotfiles outside `~/Code/dotfiles/`
