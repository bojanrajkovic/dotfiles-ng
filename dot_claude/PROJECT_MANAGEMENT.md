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
