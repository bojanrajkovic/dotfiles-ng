---
name: dox-review
description: Use when reviewing the dox document-archive queue — "show me the dox review queue", "/dox-review", "dox queue", "review flagged docs", or after an inbox/backfill run reports flags. Walks queue.yaml findings item by item, applies rulings to sidecars and entities.yaml, widens routes, performs queue-approved project-side edits, and re-runs lint/index/project.
---

# dox review sitting

Interactive review of the dox archive's flagged items. The owner rules; you apply. Full system context: the dox project doc (Outline, Projects collection) and its About child; day-to-day reference: "How to use dox (owner's manual)".

## Ground rules (violating these corrupts the system)

1. **Sidecars and `entities.yaml` are the only things you edit.** Never edit generated pages in the Documents collection — they're overwritten on projection. Hand-authored project-wiki pages may only be edited after the owner approves that specific route-suggestion.
2. **Present-then-ask, in separate turns.** AskUserQuestion dialogs swallow any text in the same turn — tables/context must END a turn, the ask comes next turn, self-contained. If the owner says "what table?", reprint standalone and re-ask (this failed twice on 2026-07-17; do not repeat it).
3. **Owner statements are facts** — record them as registry `note:` fields (dates of life events, property eras, who an org is). Facts make future extractions smarter; provenance-worthy facts should name their source doc.
4. **After rulings**: strip `needs-review` from ruled sidecars (so lint doesn't resurrect them), remove the handled entries from `queue.yaml` by id, then re-run `lint`, `index`, `project --throttle 1500`.

## Where things live

- Corpus + queue: `~/Sync/Documents/` (`queue.yaml`, `entities.yaml`, `schema.md`) — Syncthing-synced; the cron on Junction reconciles projections within minutes of edits syncing.
- CLI: the dox repo (`~/Projects/dox` on the Mac, `~/dox` on Junction) → `node dist/cli.js <cmd> --corpus ~/Sync/Documents`; Outline token: `set -a; source ~/.config/dox/.env; set +a` (needed for `project`).
- Validate YAML after every registry edit: `uv run --with pyyaml python -c "import yaml; yaml.safe_load(open(...))"`. Preserve the file's header comment (serializers drop comments — re-prepend if you rewrite).

## The sitting flow

1. Read `queue.yaml`; group findings by reason; report counts and propose an order (batch same-kind items).
2. **novel-entity** (batchable): for each minted slug, propose a disposition table — ratify with kind/aliases/note, merge into an existing slug (watch for the same entity minted in two namespaces), or alias into an existing org (e.g. subsidiary → parent). One AskUserQuestion for the batch, exceptions via notes. Apply: registry entries + fix affected sidecar tags to canonical slugs.
3. **needs-review / low confidence** (per-doc or small groups): show filename, category, confidence, flags, summary, and a text excerpt if judgment needs it. Propose a disposition per doc (accept as-is / retag / recategorize / redate). Owner-visible context first (rule 2), then ask.
4. **route-suggestion**: doc-side links are automatic; the ask is whether to add the link on the *project* page. On approval, make that one edit (Outline patch — never start replacement text with an escaped markdown char; the parser prepends `undefined`).
5. **Dates**: year-only knowledge → `YYYY-12-31` + `imprecise-date` (tax-year convention); filename dates count as hints; truly dateless stays dateless (rename pass skips those by design).
6. Rulings that reveal vocabulary gaps (new category, namespace question) → edit `schema.md` too; it and `entities.yaml` in the share are the system of record.
7. Close: apply step 4 of ground rules, then summarize rulings in the sitting's own words on the dox project doc's tracker if substantial.

## Ending early

The queue persists — the owner can stop anytime ("I can do a few"). Never rush remaining items; report what's left and how to resume.
