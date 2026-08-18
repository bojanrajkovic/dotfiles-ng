#!/usr/bin/env python3
"""Block "<test runner> ... | grep/head/tail/awk/sed" in Bash tool calls.

Piping test output means re-running the whole suite for every part of it you
want to look at. Redirect once, then read the file as often as you like.

Why Python and not shell: the shell version depended on `jq` and on GNU grep's
`\\b` and `\\s`, which BSD grep does not guarantee, so it silently allowed
everything on one platform or the other. This has no dependencies outside the
standard library and no regex dialect to get wrong.

Why shlex and not a regex over the raw string: a regex cannot tell a runner
named in *command position* from one that is merely an argument
(`grep pytest file | head`), nor tell which pipeline a command belongs to
(`pytest > out.txt; git log | head`). Lexing answers both. It does not
understand heredocs, so a script body mentioning a runner near a pipe can still
trip this; write such files with the Write tool rather than a shell heredoc.
"""

from __future__ import annotations

import json
import os
import shlex
import sys

# Commands that delegate to whatever follows them, so the real runner is later
# in the segment.
TRANSPARENT: tuple[tuple[str, ...], ...] = (
    ("uv", "run"),
    ("uvx",),
    ("poetry", "run"),
    ("pdm", "run"),
    ("hatch", "run"),
    ("pipenv", "run"),
    ("npx",),
    ("bunx",),
    ("npm", "exec"),
    ("pnpm", "exec"),
    ("yarn", "dlx"),
    ("mise", "exec"),
    ("time",),
    ("nice",),
)

# Phrases that mean "run the test suite", matched at the head of a segment once
# transparent prefixes and leading flags are stripped.
RUNNERS: tuple[tuple[str, ...], ...] = (
    ("pytest",),
    ("jest",),
    ("vitest",),
    ("rspec",),
    ("mocha",),
    ("tox",),
    ("npm", "test"),
    ("npm", "run", "test"),
    ("pnpm", "test"),
    ("pnpm", "run", "test"),
    ("yarn", "test"),
    ("yarn", "run", "test"),
    ("bun", "test"),
    ("just", "test"),
    ("make", "test"),
    ("mise", "run", "test"),
    ("cargo", "test"),
    ("cargo", "nextest"),
    ("go", "test"),
    ("dotnet", "test"),
    ("playwright", "test"),
)

READERS = frozenset({"grep", "head", "tail", "awk", "sed"})

# shlex(punctuation_chars=True) emits these as their own tokens.
SEPARATORS = frozenset({"|", "||", ";", "&", "&&", "(", ")", ";;"})


def piped_pairs(command: str) -> list[tuple[list[str], list[str]]] | None:
    """Segment pairs joined by `|`. None when the command will not lex.

    The separator has to be kept, not just the split: `;` and `&&` end a
    pipeline rather than continuing one, so `pytest; head notes.txt` runs the
    suite and reads an unrelated file.
    """
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    try:
        tokens = list(lexer)
    except ValueError:
        return None  # unbalanced quotes and the like: not ours to judge
    parts: list[list[str]] = [[]]
    joins: list[str] = []
    for token in tokens:
        if token in SEPARATORS:
            joins.append(token)
            parts.append([])
        else:
            parts[-1].append(token)
    return [
        (parts[i], parts[i + 1]) for i, join in enumerate(joins) if join == "|"
    ]


def head_of(words: list[str]) -> list[str]:
    """Drop transparent prefixes and leading flags to reach the real command."""
    rest = list(words)
    changed = True
    while changed and rest:
        changed = False
        for prefix in TRANSPARENT:
            if tuple(rest[: len(prefix)]) == prefix:
                rest = rest[len(prefix) :]
                changed = True
                break
        while rest and rest[0].startswith("-"):
            rest = rest[1:]
            changed = True
    return rest


def runs_tests(words: list[str]) -> bool:
    rest = head_of(words)
    if not rest:
        return False
    rest = [os.path.basename(rest[0]), *rest[1:]]
    return any(tuple(rest[: len(phrase)]) == phrase for phrase in RUNNERS)


def reads_output(words: list[str]) -> bool:
    rest = head_of(words)
    return bool(rest) and os.path.basename(rest[0]) in READERS


def main() -> int:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return 0
    command = (payload.get("tool_input") or {}).get("command") or ""
    if not isinstance(command, str) or not command.strip():
        return 0

    pairs = piped_pairs(command)
    if pairs is None:
        return 0
    if not any(runs_tests(upstream) and reads_output(downstream) for upstream, downstream in pairs):
        return 0

    outfile = os.path.join(os.environ.get("TMPDIR", "/tmp"), f"test-output.{os.getpid()}")
    print(
        "Do not pipe test output through grep/head/tail — this forces tests to run again\n"
        "every time you want to examine different parts of the output.\n"
        "\n"
        "Instead:\n"
        f"1. Redirect output to a file:  <test command> > {outfile} 2>&1\n"
        f"2. Read the file:              Read tool or cat {outfile}\n"
        f'3. Search the file:            grep "pattern" {outfile}\n'
        "\n"
        "This way the tests run once and you can inspect the results as many times as needed.",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
