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

if "$MISE" which git-lfs &>/dev/null; then
    # mise exec puts git-lfs on PATH even when chezmoi runs outside an
    # activated shell (e.g. the first apply on a fresh host).
    "$MISE" exec -- git lfs install --skip-repo
fi
