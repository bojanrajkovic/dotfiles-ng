---
name: dox-review
description: Use when reviewing the dox document-archive queue — "show me the dox review queue", "/dox-review", "dox queue", "review flagged docs", or after an inbox/backfill run reports flags. Walks the open findings item by item through the dox MCP tools, applies the owner's rulings to documents, entities, and categories, and resolves each finding.
---

# dox review sitting

Review the dox archive's open findings with the owner. The owner rules; you apply. Do everything
through the dox MCP tools. Do not edit corpus files, run the dox CLI, or edit Outline pages in the
Documents collection: dox generates those pages and overwrites them.

## Ground rules

1. **The owner rules, you apply.** Propose a disposition for each finding. Apply it only after the
   owner agrees.
2. **Present, then ask, in separate turns.** A question dialog hides any text sent in the same
   turn. End one turn with the table or context. Ask in the next turn, and make the question
   self-contained. If the owner says "what table?", print it again on its own and re-ask.
3. **Owner statements are facts. Record them.** When the owner states a fact about an entity (a
   date of a life event, a property's era, who an org is), save it with `upsert_entity` as the
   entity's `note`. Name the source document when the fact came from one. Notes make later
   extractions better.
4. **Resolve what you ruled on.** After a ruling is applied, call `resolve_finding` with the
   ruling in a few words. A finding you leave open comes back in the next sitting.

## Tools

| Tool | Use |
|---|---|
| `list_findings` | The open findings. Filter with `reason`. |
| `get_document` | One document's full sidecar, including its text. |
| `list_vocabulary` | The categories and entity slugs. Call it before you propose a category or tag. |
| `update_document` | Change a document's category, title, date, tags, summary, data, confidence, or flags. |
| `upsert_entity` | Add an entity, or change its aliases, note, or routes. |
| `add_category` | Add a category to the vocabulary. |
| `rename_document` | Rename a document's file after its date or title changed. |
| `resolve_finding` | Close a finding with the ruling. |
| `run_reconcile` | Re-run lint and the index. Only needed when files changed outside dox. |

Every write tool returns `{job_id, status}`. `done` means the change is written. `pending` means
the job is still running: check it with `list_jobs` before you depend on the change. An error
result carries a reason code and a hint; act on the hint, or tell the owner.

`tags` and `data` in `update_document` replace the whole list or object. Read the current values
with `get_document` first and send the full new value. `aliases` and `routes` in `upsert_entity`
work the same way.

## The sitting

1. Call `list_findings`. Group the findings by reason, report the counts, and propose an order.
   Batch findings of the same reason.
2. **novel-entity** (batch). For each new slug, propose one of: ratify it with a kind, aliases,
   and a note; merge it into an existing slug; or make it an alias of an existing entity, such as
   a subsidiary under its parent. Watch for one entity under two namespaces. Show the table, then
   ask once for the batch. Apply with `upsert_entity`, then fix each affected document's tags with
   `update_document`.
3. **needs-review** (one document or a small group at a time). Call `get_document`. Show the
   filename, category, confidence, flags, summary, and a text excerpt if the ruling needs it.
   Propose a disposition: accept as-is, retag, recategorize, or redate. Apply changes with
   `update_document`. `resolve_finding` removes the `needs-review` flag itself.
4. **unknown-category**. Either move the document to an existing category with `update_document`,
   or, if the owner wants the new category, call `add_category`.
5. **invalid-schema**. Read the detail, and fix the named fields with `update_document`. If the
   whole extraction is wrong, tell the owner; `reextract_document` replaces it with a new one.
6. **route-suggestion**. dox links the project from the document's own page. Ask the owner only
   whether the project page should link back. If yes, make that one edit to the project page in
   Outline. Then resolve the finding either way, so it doesn't return.
7. **duplicate-hash, quarantined, sync-conflict**. Show the owner the files involved and ask what
   to keep. Deleting a file is the owner's action. For a quarantined file the owner wants tried
   again, call `retry_quarantined` with the finding's `filename`.
8. After changing a document's date or title, call `rename_document`.
9. Close: report what you ruled on, what is still open, and any job that ended `failed`.

## Dates

- Only the year is known: use `YYYY-12-31` and add the `imprecise-date` flag.
- A date in the filename is a hint. Confirm it against the text.
- No date can be found: pass `date: null`. `rename_document` skips undated documents by design.

## Findings that close themselves

Lint runs after every write. A finding whose problem is fixed gets the resolution `gone` and
leaves `list_findings` without a `resolve_finding` call. This covers most `unknown-category`,
`novel-entity`, and `invalid-schema` findings. A `route-suggestion` finding, and a `needs-review`
finding whose flag is still set, stay until you resolve them.

## Ending early

The findings persist. The owner can stop at any time. Do not rush the remaining items: report how
many are open and say that the next sitting starts again with `list_findings`.
