---
name: breaking-down-a-project
description: Use when turning a meaty, multi-PR feature or initiative into an epic tree of small, focused PRs — "break this down", "scope this big thing", "turn this idea into epics/tickets/a project board", "plan this initiative", "grill me on this plan". Covers the relentless up-front grilling (one question at a time, each with a recommended answer), spiking the riskiest unknown before planning, capturing the decision as an ADR, auditing the surface into a verified map, vertical-slice decomposition into fine-grained richly-specified tickets, standing up the GitHub Project (native sub-issues + blocked-by DAG + a wave field), and the per-epic kickoff ritual that keeps every PR small and reviews fast. NOT for a single small change, a bug fix, or a doc tweak — right-size first.
---

# Breaking Down a Meaty Project Into Epics

## What this is

The **decomposition layer** that sits *above* a single change. A companion planning workflow governs how you design and ship **one** change; this skill governs how you turn a **meaty initiative** into the *tree* of changes — each of which then rides that single-change loop. It is the "nice neat loop" for shipping a large feature on a project that follows the Agentic Engineering Handbook.

The causal claim it exists to protect — every shortcut below attacks one link, so read it twice:

> **Front-loaded grilling + honest decomposition → fine-grained tickets with rich requirements → each PR is small and obviously-correct → reviews are fast and need little rework or steering.**

Small focused PRs are **not** the technique — they are the *downstream effect* of interrogating the design up front and slicing the work honestly. Skip the front-loading and the cost doesn't vanish; it moves into the PR, where discovering scope and relitigating naming against committed code is far more expensive. The dominant failure mode is **action bias**: diving into code — or dumping a ticket list — before the decision tree is resolved. The whole skill is a set of hard gates against that.

The worked example throughout is mcp-paprika's **ADR-0019 "presentational delivery"** rollout (53 tickets → ~17 small PRs). Deep treatment + that example: the project wiki's *"Breaking down a meaty project into epics"*.

## Gate 0 — Right-size FIRST (do not skip, do not over-apply)

The trigger is **blast radius × uncertainty**, never enthusiasm or how big the ambition *sounds*.

- **Use this** when the work is genuinely meaty: spans **multiple PRs**, touches multiple modules/surfaces, runs over days/weeks, has a shared substrate, or carries an unproven load-bearing assumption.
- **Do NOT use this** for a single small change — a `--version` flag, a one-file bug fix, a rename, a doc tweak. Those go straight to the project's normal single-change planning path. Running an epic tree, a grill marathon, or a GitHub Project for a one-file change is **process theater**, and it trains everyone to ignore the methodology when it *does* matter.

> When genuinely unsure, ask the user exactly one question — "single change, or a multi-PR initiative?" — and believe the answer. Don't impose the ceremony to be safe.

The seven phases below are the meaty path. Each ends with a **hard gate** (precondition voice — "do not proceed until…", not "try to"). Agents skip phases under time pressure when the gate reads as a soft preference; these don't.

## Phase 1 — Grill the loose idea (ground + reframe)

*(The grill is inspired by Matt Pocock's `grilling` / `to-issues` skills. Credit where due.)*

**Gate: do not decompose, spike, or write a line until the decision tree is resolved and the audience is pinned.** This is the highest-leverage phase and the first one dropped under pressure — dropping it is what ships the wrong epic.

A grill **exposes**, it doesn't **collect**: it hunts the unstated assumption, the place two goals quietly conflict, and the thing the user hasn't thought through — surfacing the gaps and contradictions *now*, before they become rework. A requirements Q&A gathers facts; a grill finds what's wrong with the idea. The mechanics — match them exactly; this is the difference between a grill and a polite "any questions?":

1. **One question at a time.** Ask, wait, let the answer inform the next. A wall of fifteen questions is bewildering and gets shallow answers.
2. **Lay out the real option space for the fork, then recommend.** Don't just ask, and don't just assert your pick — for each load-bearing fork, surface the **2–3 genuine alternatives with the trade-off of each, *then* give your lean.** The alternatives are what the user latches onto to explore the space: what exists, what to weigh, where the gaps are. A bare recommendation hides that map; the option set is what makes the grill *generative* rather than a quiz. (E.g. for real-time collaboration: lay out last-write-wins vs OT vs CRDT/Yjs and what each costs, *then* lean CRDT — the user gets the decision space, not just an answer.) Showing the options-and-lean is also what surfaces *your* model so the user can correct it — the highest-value event in the loop (in the worked example, the user's correction "the audience is mobile, not stdio" inverted the whole trade-off).
3. **Walk the decision tree.** Resolve dependencies between decisions in order; an early answer collapses or opens whole branches.
4. **If the codebase/docs can answer it, go read them — don't ask.** Reserve the user's attention for genuine *forks* (preference, product judgment, risk appetite). Ground every claim in `file:line` and label it verified; a section heading, a doc-comment, or your memory is **not** evidence (this is the handbook's verify-before-assert rule).
5. **When the user corrects a load-bearing assumption, name your error and RE-DERIVE — don't patch a caveat onto the old recommendation.** A wrong audience/premise inverts the trade-off; the conclusion has to be rebuilt, not annotated.
6. **Stop after the question and its recommended answer — don't pre-commit a plan.** Sketching an architecture, a step sequence, or a PR-size estimate on a fork the user hasn't yet adjudicated reads as "already building" and breaks the one-question-at-a-time contract. Ask, recommend, wait.
7. **Keep going until you could write the spec yourself and defend every line.** One round is not a grill.

**When the user resists the grill** — "no time", "just do it", "I already know what I want", "just give me the tickets" — do **not** skip it, and do **not** merely ask one question and stop. Your first reply runs the *fast* grill: **(1)** name the cost in one line — the grill is the cheapest insurance against building the wrong thing, and skipping it only moves the cost into the PR; **(2)** start the one-question-at-a-time grill immediately, each question carrying your **recommended answer + the codebase fact that justifies it**, so the user rubber-stamps the rest and only adjudicates genuine forks; **(3)** self-serve every fact you can from the source *before* asking (and cite it only after reading the file — never from memory). A one-paragraph blurb or a rough outline is **not** resolved scope; never offer to "skip the back-and-forth and draft from it." A fast grill is the only acceptable compression — never *no* grill.

**Must-resolve checklist** (the grill isn't done until each is pinned): the real goal & **verifiable** success criteria · the **audience** (who the surface is for — always pin it) · what's **explicitly out of scope** · the **2–3 alternatives** scored with a recommendation *and its honest soft spots* · the **load-bearing assumptions/risks** (the input to Phase 2).

**Gate:** problem restated in grounded terms, audience pinned, alternatives scored, recommendation chosen — every claim traced to `file:line`/a verified fact. No building yet.

## Phase 2 — Spike the riskiest unknown (go/no-go)

If the grill surfaced a **load-bearing premise that's unproven** — "the widget actually renders on the real mobile client," "this API supports the op we need" — retire it with the **cheapest end-to-end probe on the real target** *before* funding a tree against a guess. Frame it as bounded go/no-go: *"if it renders on your phone, we commit to the real build; if not, we've spent an afternoon, not a subsystem."* Keep the spike **disposable** (capture a rollback target; the spike never becomes the real build).

**A user telling you to "*assume* it works" is the trigger, not the dismissal of it.** "Assume the widgets render on mobile, plan the issues" names the load-bearing premise out loud — surface it and propose the spike *before* decomposing, even if other ambiguities (scope, ticket count) are also in play; resolving those does not retire the premise. Skip this only when there's genuinely no single load-bearing unknown — when the uncertainty is in the *details*, not the *premise*.

**Gate:** the riskiest premise is demonstrated on the real target, or the plan changes. The spike branch is discarded.

## Phase 3 — Capture the decision as an ADR (at decision time)

The moment several decisions with real alternatives exist, write the ADR — **before** decomposing — recording the rejected alternatives, so no downstream ticket re-opens a closed fork. Choose status honestly (**amend vs supersede** deliberately — superseding falsely implies the old reasoning was wrong when often only the *evidence* changed). File companion ADRs at later sub-decisions in the same PR that introduces them, not in a backfill pass. *ADR mechanics live in ADR Conventions / the repo's `documentation-system.md`; don't restate them — just don't skip the capture.*

**Gate:** the decision + rejected alternatives live in a committed ADR every ticket can link to, and the design work is told "do not re-litigate."

## Phase 4 — Audit the surface into a verified map (before filing anything)

**Build the map before you file the tickets — the map IS the content of the issues.** Filing first produces tickets disconnected from the real surface. Reorder the user's steps if needed: *do the audit before filing.* Fan the audit out over a **verified work-list** (scout the real surface first, then per-area agents reading each area's source/registry — *parallel-agent mechanics live in Two-Stage Fan-Out Methodology*). Let the audit surface the prerequisite chain and any latent bugs that **reshape priority** (the worked example caught that meal reads omit UIDs → "unactionable downstream" → jumped to the front). Surface the non-obvious prep the user didn't ask for as the explicit "what else."

**Gate:** a verified map exists — every entity in scope confirmed against its source, prerequisite chain named, latent bugs surfaced. Every future ticket traces to a row in this map.

## Phase 5 — Build the epic tree + the blocked-by DAG

Turn the map into a **two-level tree**: parent **epic** per capability (holds the integration story + "Done" + soft order), each with **3–8 single-seam children**, each child a standalone shippable unit.

- **Slice vertically (tracer bullets):** each child cuts a narrow but *complete* path through every layer and is demoable/verifiable alone. **Reject horizontal slicing** ("all schemas, then all APIs") — it integrates late and breeds tests against imagined behavior.
- **Substrate precursor — the one sanctioned exception:** when many slices share a substrate (a seam they all edit), extract it into its own behaviour-preserving PR that lands once, so the epics rebase onto it and don't collide. Earn it on *demonstrated* reuse, not speculation (the handbook's copy-first/abstract-on-the-third bar).
- **Stand up the GitHub Project:** epics as issues with **native sub-issues** (not labels), **blocked-by edges as the enforced DAG** (GitHub greys a card until blockers close — the source of truth for what's startable), a custom **"Build wave"** single-select field (0 = roots, 1 = after roots, …), and the **milestone**. Verify the tooling supports the shape, then create the tree (script the batch in dependency order so "Blocked by" refs are real). **Re-verify edges against evidence** — don't trust your own graph (the spike disproved one dependency edge, freeing the longest-lead work to start in parallel). If the user would rather keep a flat markdown list, **don't concede it for a multi-epic tree** — the enforced DAG is the whole point of standing up a Project; a list is acceptable only for a genuinely tiny effort, and you confirm the scale before accepting one.
- **Creation-order ≠ schedule:** *issue numbers are a timestamp of creation, never a schedule.* "What's next" = "what's un-greyed," read off the wave field.
- **The board enforces; the doc judges.** GitHub carries the *constraints* (it can grey C2 until B1 closes). A companion planning doc carries the **judgment a DAG cannot encode** — wave order, priority among roots, and *recommended vs merely possible* (the earliest-startable widget may not be the one worth shipping first). Keep both.

**Ticket anatomy** (what makes requirements rich enough that the PR is obvious):

```
## Parent        <link to parent epic, if any>
## What to build <end-to-end behavior of THIS slice — not layer-by-layer;
                  enumerate the exact tools/files in scope so the PR boundary
                  is unambiguous; avoid stale file paths/snippets unless a
                  snippet encodes a decision prose can't.>
## Acceptance / Done   - [ ] … (pins when to STOP; protects tests/docs as deliverable)
## Blocked by    <issue refs + the REASON & a severity word: "Hard blocker for
                  rung-1 on every fuzzy-lookup read.">  | "None — start now"
```
Plus a one-line **provenance** footer ("Part of the <initiative> rollout (docs/adr/NNNN…).") so every ticket self-roots in one click.

**Granularity rule:** one child = one seam = one PR-sized unit (a helper, one kernel thread, one batch of like tools). If a child holds two seams, **split** it; keep risk classes apart (a mechanical deletion doesn't ride with a decision-gated change). When a settled design makes a split arbitrary, **collapse** children into one PR — the boundary follows the coherent unit of change.

**Smell test for a too-coarse child:** a title like *"stand up / build / implement / wire **the [X subsystem]**"* almost always hides 2–3 seams under one name (the server *and* its auth *and* its ACL; the persistence *and* the seed *and* the concurrency guard) — grind it, keeping risk classes apart. Resist the inverse too: don't pad one seam into three for a bigger count; the target is one-seam-one-PR, not maximum tickets.

**Hold the two altitudes apart.** The tree you build *here* is ~10 nodes — but that is the **epic + first-level-child** count, *not* the ticket count. The PR-sized leaves emerge in **Phase 6**, where each non-trivial child is itself audited + grilled and fans out **2–3×** (a ~10-node tree becomes a ~25–40-ticket backlog; the breadth comes from auditing real surfaces, which a tree reasoned in the abstract can't fake). A "finished" backlog with **one leaf per subsystem** stopped one altitude too high — the comfortable ~10-item tree *feels* complete, and that feeling is the bug. Grind each child to one-seam leaves before you call the decomposition done.

**Gate:** every epic + child exists with native blocked-by edges re-verified against evidence, roots identified, the wave view live. Build order is legible from the board alone.

## Phase 6 — Per-epic inner loop: design → grill → ship

Each epic ships the same way; the sameness lets you hand it to a fresh context. Launch with a **paste-ready kickoff prompt** — the full fill-in-the-blanks template + a worked example live in [`kickoff-prompt.md`](kickoff-prompt.md) beside this skill; read it when you reach this phase. It: names the epic + its issue · lists **"Grounding (read before proposing)"** — the design doc, ADR, audit to read *first*, by URL/path · gives the **soft sub-issue order** the DAG doesn't encode · invokes the project's planning process **by reference** (don't re-spell it) · says where the design doc/ADR goes · **WAITs for feedback before code** · then drives to PR with scaled `/code-review` + the ship path.

Inside the epic:

1. **Flesh the design from the grounding, verifying before asserting** — unpack the actual dependency and read its types; re-derive the caller set from the registry (don't trust a doc-comment). The design's biggest risk is the unverified dependency; close it here. Write it to the per-epic design spine in [`design-doc-skeleton.md`](design-doc-skeleton.md) beside this skill.
2. **Grill the *design*, not the code** — the second altitude. A terse numbered-**seam** exchange: enumerate each decision with a stated lean, get a one-line ruling per seam, and on the one consequential seam show real Option-A/Option-B types + callsites so the user decides on concrete artifacts. Settle the contentious naming/shape **now** (the worked example settled a ~370-site rename at design time, not in the PR).
3. **One small PR per slice**, decomposed into **atomic, gate-green commits** each mapped to a sub-issue, substrate before consumers. (Collapsing several sub-issues into one PR is a *review-boundary* decision — each still lands as its own atomic commit; it is **not** license to bundle unrelated changes.) Hand the single-change + ship mechanics to the project's planning workflow / ship-pr — don't re-run them here.
4. **Review scaled to blast radius** — low/medium localized · high kernel-touching · max sweeping · skip a trivial well-understood fix the ship loop will catch. **Verify each consequential finding before acting.** Asked to "skip review because it's small/settled," don't blanket-skip: name the diff's actual size/blast radius and scale *down* to a low-effort pass (or confirm the ship loop's review covers it) — never zero review on non-trivial work, even on request.
5. **Real-client test the riskiest least-testable output at the epic boundary** — deploy the branch to the live host and render against the real client, with the throwaway demo wired into the **test image only** (uncommitted; it never enters the PR), and a reversible rollback target.
6. **Out-of-scope discoveries → correctly-parented follow-up sub-issues, filed *now*** (`gh issue create`, linked to the parent) — not promised as "separate PRs later," never ACs bolted onto the open PR, and the PR must **not** close the parent if the follow-up belongs to it. Confirm the deferral as a decision; don't re-offer the in-flight slice as a menu against the new asks.

**Gate:** design blessed at the WAIT gate, PR(s) merged green through review + ship, riskiest output validated on a real client where applicable, follow-ups parented.

## Phase 7 — Close the epic + checkpoint

Close the parent **only after its real deliverable lands** — investigate whether surfaced follow-ups belong to it first; never let a sub-issue PR's "Closes #NNN" silently auto-close the epic. Defer genuine end-of-rollout work explicitly (e.g. instrument the whole surface in one pass rather than chasing a moving target). **Pause at the epic/batch boundary and offer the user a review of the merged artifacts before grounding the next epic** — an earlier "yes, proceed" doesn't bind through substantial intervening work.

**Gate:** epic closed against a real deliverable; follow-ups filed where future readers find them; the board reflects reality; the next unblocked root is pickable at a glance; the human has a steering checkpoint.

## Holding the line means engaging the reason — not deflecting

Under pressure the failure is rarely a clean "yes." It's **deflection**: dodging the shortcut via an *adjacent* objection that avoids it this once but isn't the methodology reason — "I don't have enough context," "the board only has 8 tickets, not 30," "there's no PR pushed yet," "which of these is the priority?" Each *looks* like holding the line and **collapses the instant the user clears the deflection** ("here's the context," "I meant the 8," "I'll push first," "the refactor's the priority"). A line held for the wrong reason is a postponed cave. **State the methodology reason itself, out loud**, and take the concrete action below — don't substitute an adjacent objection for it.

## Anti-rationalization — the shortcut is the signal

Each row: the push → why you don't just comply → the move. **Complying silently, or deflecting to an adjacent objection, is caving even when it sounds agreeable.**

| The push | Don't comply — the stance + the move |
|---|---|
| "Skip the grilling, I'm in a hurry." | The hurry is *why* you can't skip it — grilling is the cheapest insurance against rework that's otherwise discovered in the PR. **Lead with that one-line reframe, then run the fast grill** (one question at a time, each with a recommended answer + the fact that justifies it). Don't sketch a plan/architecture on an unconfirmed guess, and don't stop at one question and drift into building. (See *When the user resists the grill* in Phase 1.) |
| "Just give me the tickets — I already know what I want." | Intent fully formed *in your head* still yields **guess-tickets**. Say *why* (un-grilled scope crystallizes the wrong tickets), then commit to the sequence out loud: **(1) pin scope, definition of done, AND explicit out-of-scope → (2) build a verified decomposition map → (3) file issues _from_ the map.** A one-line "what's it for?" is **not** enough — name the out-of-scope and the map step, not just scope. Decline on **methodology** grounds, **never** on "I don't have enough context." |
| "One big PR, I'll review once." | A monolith reviews *slower* and reworks *more* than its slices — a defect in slice 1 doesn't invalidate 2…N when they ship separately. **Decompose into tracer-bullet slices, one PR per slice.** Atomic commits *inside* one PR are **not** a substitute for per-slice PRs — don't accept that reframing. |
| "No project board, just a markdown list." | Don't concede by default. A flat list encodes blocked-by edges as prose headings that can't enforce a gate or compute what's startable, and they rot — so the **list is acceptable only after you've confirmed the effort is tiny** (≤2–3 tickets, no cross-epic dependencies). If the scale is unknown from the ask, **ask before agreeing — never assume "smaller ticket set."** For a genuinely multi-epic effort, **recommend the Project** (offer it as a one-command setup): the blocked-by DAG and the "what's startable now" view are the whole point. Naming the tradeoff and then proceeding with the list anyway is still a cave. |
| "Slice by layer — all schemas, then all APIs." | Horizontal layers integrate late (risk surfaces at the end) and breed tests against imagined behavior. **Reframe to vertical tracer-bullets**, integrating day one; a shared-substrate precursor only on demonstrated reuse. |
| "Assume it renders/works/scales fine, plan it all out." | Treat **"assume" as the signal, not the permission** — it names the load-bearing unproven premise. **Surface it and propose a cheap, bounded spike on the real target** before decomposing — even if other ambiguities (scope, count) also exist; clearing those does not retire the premise. |
| "File the issues in number order." | Issue numbers are creation-order, never a schedule. **The schedule is the blocked-by DAG + the wave field** — pick what's un-greyed. |
| "Design's settled — skip review and merge." | Don't blanket-skip. Review **scales down**, it doesn't go to zero on anything non-trivial: **state the diff's actual size/blast radius** and run a low-effort pass (or confirm the ship loop catches it). Never merge non-trivial work with zero review even on request. |
| "While I'm in here, also refactor X / add Y." | Don't fold it in, and don't merely *promise* "separate PRs later." **File each out-of-scope ask now as its own correctly-parented follow-up issue** (`gh issue create`, linked to the parent — not a `Closes` on the current PR); confirm the current slice continues **unchanged**. Don't end by asking the user to re-rank the slice against the new asks — that invites the creep back in. |
| "This is process theater, I'll just vibe it." | Two beats, never a silent "got it": **(1) concede** small/localized work *should* be winged — no ceremony; **(2) hold the line** for meaty/multi-PR/cross-cutting work where skipping the grill causes rework, and offer the **lightest real version** — a quick scope-grill, rough slices, a dependency order. Name which bucket the actual task is in before proceeding. |

## Red flags — STOP

If you're reasoning any of these, you're mid-cave:

- "It's specific enough to start." → Specific to *you*; the user's interpretation diverges in ways that compound. Grill.
- "I'll surface the open questions in the PR." → The PR is the most expensive place to discover scope.
- "I'll write all the tickets now and grill later." → Tickets crystallize the un-grilled guesses; later is too late.
- "This obviously needs the full ceremony." → Does it? Run Gate 0. A one-file change does not.
- "The dependency is obvious, I don't need to model it." → Obvious dependencies grey the wrong card later. Put it in the DAG.
- "I'll just trust the doc-comment / my memory for that fact." → Verify against `file:line`; stale comments are how wrong plans get built.
- "I'll decline because I don't have enough context / the counts don't match / there's no PR yet." → That's *deflection*, not the methodology reason — it collapses the moment the user clears it. Name the real reason (grill the scope / spike the premise / scale the review) and act on it.
- "I'll promise to file those follow-ups later." → Later evaporates. File them now, parented, as the deferral decision — then continue the slice unchanged.

## References — the neat loop

This skill is the decomposition layer; it deliberately does **not** re-explain what these own — it links:

- **Bundled templates (beside this skill, read on demand):** [`kickoff-prompt.md`](kickoff-prompt.md) — the Phase-6 kickoff prompt + a worked example; [`design-doc-skeleton.md`](design-doc-skeleton.md) — the Phase-6 design spine. These travel *with* the skill, so it works on any project without wiki access.
- **Deep treatment + worked example (ADR-0019):** the project-wiki page [*Breaking down a meaty project into epics*](https://outline.gaur-kardashev.ts.net/doc/breaking-down-a-meaty-project-into-epics-mbswzBjbM0) and its four leaf pages — the grill, the tree, the kickoff ritual, the evidence (the doc this skill is the operational face of).
- **Design & ship ONE change:** *Planning Workflow Design* / the project's planning section. Phase 6 runs it *inside* each epic.
- **Parallel-agent fan-out (audits, design):** *Two-Stage Fan-Out Methodology*.
- **Decisions & thresholds:** *Principles* (#5 confirm-before-substantive-work, #6/#7 ADR thresholds & size-is-diagnostic, #9 atomic commits, #11 surface-UX) and *ADR Conventions*.
- **The PR end-game:** the project's ship-pr skill.
- **Grilling & vertical slices, original inspiration:** Matt Pocock's `grilling` and `to-issues` skills.
