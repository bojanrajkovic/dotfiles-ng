#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Match: <test runner> ... | grep/head/tail/awk/sed
if echo "$COMMAND" | grep -qE '\b(npm( run)? test|pnpm( run)? test|yarn( run)? test|npx jest|just test|jest|vitest|pytest|cargo (nex)?test|go test|dotnet test|ruby -e|rspec|mocha|bun test|make test|playwright test|mise run test)\b' \
   && echo "$COMMAND" | grep -qE '\|\s*(grep|head|tail|awk|sed)\b'; then
  OUTFILE=$(mktemp -t test-output)

  cat >&2 <<EOF
Do not pipe test output through grep/head/tail — this forces tests to run again
every time you want to examine different parts of the output.

Instead:
1. Redirect output to a file:  <test command> > ${OUTFILE} 2>&1
2. Read the file:              Read tool or cat ${OUTFILE}
3. Search the file:            grep "pattern" ${OUTFILE}

This way the tests run once and you can inspect the results as many times as needed.
EOF
  exit 2
fi

exit 0
