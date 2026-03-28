#!/bin/bash
set -euo pipefail

MISE="${HOME}/.local/bin/mise"

if [ ! -x "$MISE" ]; then
    echo "mise not found, skipping tool installation"
    exit 0
fi

echo "Installing mise-managed tools..."
"$MISE" install --yes

echo "mise tool installation complete!"
