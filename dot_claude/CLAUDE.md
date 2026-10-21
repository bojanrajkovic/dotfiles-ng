# Important Stuff

- Project docs document what _is_, not the journey — cut "we tried X", "empirically observed",
  PR/SHA references, and first-person anecdotes.
- Default to including a diagram whenever it clarifies a flow, sequence, state machine,
  architecture, or data shape, not only when asked. ASCII diagrams on the terminal, Mermaid in docs.
- Python — never `pip install` for ad-hoc work. For one-off scripts and tool invocations, use
  `uv run --with <package> python -c '...'` (or `uv run --with <package> <command>`). For durable
  scripts, write uv modelines to enable easy execution.
- Use the AskUserQuestion tool whenever you have questions for me, instead of presenting me with
  text options. Make sure to explain the question adequately and give me the reason for the
  recommendation.
- You should always search Outline and local working directories for anything relevant to the
  current conversation before starting work.
- Flag things that are worth flagging up front, don't just say/insinuate things are "worth flagging"
- There may be other Claude instances working in the same repository. If `groundcrew` is available,
  run `groundcrew skills finding-peers` to learn how to find other sessions that might be working
  in the same repository as you.
- 1Password on Linux: `op` goes to op-gate, which asks me to approve each call on my phone. It
  allows only `read`, `whoami`, `item get/list`, `vault get/list`, and `document get`, with the
  subcommand first (`op item get X --format json`, not `op --format json item get X`). It can't
  read the Employee or Private vaults and can't write. For those, use `op-mac`, which waits for
  Touch ID on my Mac. Check `curl -fsm2 http://127.0.0.1:18340/health` first; if it fails, no Mac
  is connected, so ask me. If a request is denied or times out, tell me what it needed and don't
  retry.

# Writing Rules

These rules apply to *ALL* writing. Your own outputs to me, written documentation, commit messages
and bodies, pull request titles and bodies. If it's written word and it's meant to be seen by a
human, it should follow these rules:

- Use "Standard Technical English." Don't get too lost in project jargon, don't create project
  specific jargon. Short and to the point is *always* preferable to volumes.
- Clarity, conciseness, consistency, and authenticity are paramount. Writing must not feel robotic.
- Clarity: short sentences (15-20) words, short paragraphs (4-6 sentences), active voice, one
  concept per paragraph.
- Conciseness: every word serves a purpose, remove noise and filler. No throat clearing, flourishes
  ("the gate fails open"), hedging, or marketing fluff. Use direct, simple language: Standard
  Technical English.
- Consistency: same terminology, voice, and structure throughout. Pick one word and stick to it, use
  consistent formatting, maintain tone, and follow established patterns.
- Authenticity: remove AI "tells" such as gratuitous em-dashes, throat-clearing and hedging,
  "Opus-ese" flourishes ("the gate fails open", "<whatever> bites", etc.), hedging language,
  transition word overuse.
- Explain why when: recording design decisions with tradeoffs ("we use pagination instead of cursors
  because..." good, "we use pagination." bad), non-obvious patterns, or breaking from conventions.
- Progressive disclosure gives readers offramps. Layer complexity: simple first, then depth. The
  general pattern should be: basic explanation, simple example, advanced section, reference.
- Use contractions, vary sentence length as appropriate, add personality (I, we, anecdotes grounded
  in experience), be specific (humans are specific).

## Anti-patterns to avoid when writing

* The jargon firehose: "Simply connect your ETLOrchestrator to the HydraNode endpoint. Once a
  connection is established, instantiate a DataStream by passing your KinesisConfiguration." The
  right fix is to define terms, link to prerequisites, and provide a Getting Started.
* Perfect world examples. No code runs in a perfect world, so when writing example code, include
  real error handling appropriate to the snippet.
* Vague/unhelpful/tautological documentation. For example, a docstring that says "gets a user by ID"
  for a function getUserById. Instead, describe behavior, parameters, return values, exceptions,
  etc.

## Positive Examples

* "Row Level Security (RLS) is a PostgreSQL feature that allows you to control which rows a user can
  access in a table. When you enable RLS on a table, all SELECT, INSERT, UPDATE, and DELETE
  operations are subject to a security policy. A policy is a SQL expression that returns a boolean
  value. If the expression returns true, the operation is allowed to proceed. If it returns false or
  null, the operation is denied." Defines RLS, explains scope, defines the mechanism. Dense, but
  clear.
* "Stripe uses conventional HTTP response codes to indicate the success or failure of an API
  request. In general: Codes in the 2xx range indicate success. Codes in the 4xx range indicate an
  error that failed given the information provided. Codes in the 5xx range indicate an error with
  Stripe's servers." Establishes a predictable contract, immediately useful, technical, precise.
* "You can run create-astro anywhere on your machine, so you don't have to create an empty directory
  for your project first. If you don't have an empty directory yet, the wizard will help you create
  one." Astro anticipates a common beginner question and answers it immediately.
* "The biggest maintainability concern when using a utility-first approach is managing commonly
  repeated utility combinations. The traditional approach is to extract repeated utilities into a
  component class. We believe that @apply should be used sparingly. The best way to manage repeated
  utility combinations is to create reusable components with a templating language." Tailwind
  identifies the problem, presents the common solution, explains why it's suboptimal, and then
  guides towards a better one. Teaches philosophy *and* pushes into the pit of success.

# Durable Records

@OUTLINE.md

# Project Management

If I talk about creating/updating a project, read PROJECT_MANAGEMENT.md.

# Designing, Planning, and Executing Work With Me

These are steps to follow whenever we're building new features, fixing bugs, etc.:

* Run the /grill-with-docs skill to ask clarifying questions, sharpen the idea, brainstorm
  alternatives, and iterate on the design.
* Read & explore the code for facts, use documentation as a guidepost.
* Walk me through the design in sections (one section at a time, stop for go ahead between sections)
  when completed as a final pass at refinement if needed.
* Use GitHub's new stacked PR feature to split bigger builds across multiple easy-to-review PRs.
* Load the Skill tool and use the `/ponytail` skill in ultra mode before designing
* Load the Skill tool and run `/ponytail-review` after designing and after writing code.
* Run a code review at the appropriate altitude after each change — use the `/code-review` skill's
  patterns. Surface a recommendation for apply/defer, and look to fix problems structurally rather
  than patching cases individually.
* Write/update documentation with the change, don't batch it for later.
* Use TDD whenever it makes sense to.
* Strong, strict typing & "making illegal states unrepresentable" should be an ethos.
  * Don't split off a union member just because one case carries an extra field. If every case
    can supply it, make it required on all of them. Don't make a field optional when the data
    always exists.
  * A type's name must cover everything it reads as: `IgnoreReason` includes every ignore reason.
  * No `New<X>` input types. Derive the shape with `Pick<>`/`Omit<>`. When that loses a union or a
    brand, name the type for what's true of the value (`SavedAttachment`, not `NewAttachment`).
* Prefer an established library (pino, etc.) over a hand-rolled helper. Saving a dependency isn't a
  goal.
* When dropping an idea or experiment, close its issue with a one-line reason and remove it from
  the docs. No ADR for dead ideas; ADRs are for decisions that shape what gets built.

## Code shape

* Keep domain services apart from HTTP/RPC controllers. Controllers parse input, call a service,
  and map the result.
* SOLID without overengineering. Don't start with a DI framework or repository interfaces. Pass
  dependencies by hand until wiring them gets painful, or until there's a second real
  implementation of the interface.
* Keep pure decisions (retry or give up, accept or reject) out of the service, so they're testable
  without its dependencies. In TypeScript, that's an exported function in the domain file that
  returns a discriminated union. Elsewhere, use whatever the language prefers: a static method or
  a small value type. Service methods stay short and orchestrate the steps.
* Blank lines separate a function's phases: write, span attributes, metric, log.
* Use a child logger per module and per unit of work, with its IDs bound.

## Tracing

* Add a span wherever time can be spent or failure can happen: each I/O boundary and each service
  operation. Put outcomes and IDs on it as attributes, so traces can be filtered on them.
* A cheap pure function gets no span; its results become attributes on the caller's span. A pure
  function that can be slow (rendering, a regex over large input) gets one.
* Use span events only for rare moments with no duration, such as a scheduled retry.
* Never put user content (message text, names, URLs) in span attributes or logs.

## Reviews and merging

* After opening a PR, stop and let me review it. Merge only when I say to merge that PR or stack.
  "Build it" means write the code and open the PR. An earlier "merge it all" covers only the PRs it
  named.
* For review, give me one line per PR: its link and what to look at. Don't paste diffs into the
  reply, and don't run `git show` or `cat` to "show" me something; I can't see tool output.
* To wait for CI, run `ci-wait` (in `~/.local/bin`). Don't write your own polling loop or use
  `gh pr checks --watch`, which exits early when checks haven't registered yet. `ci-wait` takes a
  PR number, PR URL, branch, or SHA, and defaults to local HEAD, which must be pushed. It waits for
  every check run and commit status, including late ones, then prints each check's result, URL,
  and run/job IDs, plus `gh run view --log-failed` commands for failed jobs. Exit codes: 0 passed,
  1 failed, 2 bad input or API errors, 3 timed out, 4 no checks. CI can take a while, so run it in
  the background. See `ci-wait --help` for options.

# Writing Commits As Me

* Use atomic commits — one logical, self-contained change per commit, project checks all pass.
* When creating PRs, check the repo's merge strategy / recent PR shapes to match the style. For
  squash merges, assume that the PR body is the merge commit's body, so write it accordingly.
* Verification content like test plans, screenshots, etc. goes in a PR comment.
* You may upload screenshots/recordings to the coderinserepeat.com s3 bucket, under the junk folder
  — look at the folder structure for understanding. The bucket is served from coderinserepeat.com.
