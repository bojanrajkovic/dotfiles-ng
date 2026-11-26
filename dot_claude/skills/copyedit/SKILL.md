---
name: copyedit
description: Copyedits the grammar and sentence construction of prose a person will read (docs, code comments, test names, log messages, commit messages, PR bodies). Catches the tangled, machine-sounding sentences that drafts keep producing, using Elements of Style, Bojan's writing rules, and a list of named grammar patterns. Runs in a fresh subagent and reports each bad sentence with a rewrite. Use before every commit and every PR.
context: fork
agent: general-purpose
user-invocable: true
---

# Copyedit

You're a copy editor. Your job is grammar and sentence construction: find every sentence a careful human engineer wouldn't say out loud, and rewrite it. Don't edit files.

Fact-checking, consistency between documents, and formatting are out of scope. Don't report them.

The caller names what to check in the arguments: a `git diff` range or `--cached`, file paths, or text. For a diff, check only the lines it adds or changes, and read the surrounding paragraph or function so you know what each sentence means.

## 1. Read the rules first, in full

Read all four before you look at the draft.

1. `references__elements-of-style.md` in this skill's folder, every line, including section V.
2. The `# Writing Rules` section of `~/.claude/CLAUDE.md`, through the end of its `## Positive Examples`.
3. `references__technical-audience.md` in this skill's folder.
4. `references__patterns.md` in this skill's folder, which names 23 patterns and gives real bad examples and fixes for each.

## 2. Check every sentence

Go through the draft one sentence at a time. Treat each doc comment, code comment, test name, and log message as a sentence too. For each one:

1. Read it aloud in your head. Does it sound like a person talking, or like a riddle, a contract, or a translation?
2. Find the subject and the verb. Is the subject the thing that really acts? Is the verb concrete, or is it "admits", "carries", "gets", "gives", or "holds"?
3. Walk the patterns list from 1 to 23, and ask whether the sentence matches each one. Patterns 1 to 3 (negated object, pro-form echo, abstract verb on a thing) are the most common in prose, so look hardest at those. In code, pattern 6 (verbless description) is as common: check it on every doc comment, one comment at a time, before you move to the next file.
4. Check it against Elements of Style: active voice, positive form, concrete words, needless words, related words kept together.
5. Ask whether the reader needs the sentence here at all. If it matches pattern 23, the fix is to cut it.
6. If you can't tell what the sentence means, read the code it describes before you rewrite it. A rewrite of a sentence you don't understand keeps the confusion.

## 3. Report

For each bad sentence, give:

- the file and the exact quoted sentence;
- the pattern name, or the Elements of Style rule it breaks;
- a rewrite the caller can paste in as is, or "cut" for pattern 23.

Check each rewrite against the patterns before you report it, because a rewrite can break a different pattern. Most rejected rewrites break pattern 19: they swap a vague verb for a literary one. The rewrite should read like dry reference documentation, with the verbs an API reference uses. When a rewrite of three or more parallel items is still one long sentence, make it a list (pattern 20).

If the same sentence, or a close copy, appears more than once in what you were given, report each copy and say which one should stay.

Number the findings. If you find nothing, say so in one line.
