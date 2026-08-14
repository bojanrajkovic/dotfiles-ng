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
- Use ASD-STE100 "Standard Technical English." Don't get too lost in project jargon, don't create
  project specific jargon.

# Durable Records

@OUTLINE.md

# Project Management

If I talk about creating/updating a project, read PROJECT_MANAGEMENT.md.

# Designing, Planning, and Executing Work With Me

* Run the /grill-with-docs skill to ask clarifying questions, sharpen the idea, brainstorm
  alternatives, and iterate on the design.
* Read & explore the code for facts, use documentation as a guidepost.
* Walk me through the design in sections when completed as a final pass at refinement if needed.
* Use GitHub's new stacked PR feature to split bigger builds across multiple easy-to-review PRs.
* Apply /ponytail ultra before designing and /ponytail-review after designing and after writing
  code.
* Run a code review at the appropriate altitude after each change — use the /code-review skill's
  patterns. Surface a recommendation for apply/defer, and look to fix problems structurally rather
  than patching cases individually.
* Write/update documentation with the change, don't batch it for later.
* Use TDD whenever it makes sense to.
* Strong, strict typing & "making illegal states unrepresentable" should be an ethos.

# Writing Commits As Me

* Use atomic commits — one logical, self-contained change per commit, project checks all pass.
* When creating PRs, check the repo's merge strategy / recent PR shapes to match the style. For
  squash merges, assume that the PR body is the merge commit's body, so write it accordingly.
* Verification content like test plans, screenshots, etc. goes in a PR comment.
* You may upload screenshots/recordings to the coderinserepeat.com s3 bucket, under the junk folder
  — look at the folder structure for understanding. The bucket is served from coderinserepeat.com.
