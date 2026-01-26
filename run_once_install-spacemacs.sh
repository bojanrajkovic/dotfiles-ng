#!/bin/bash

set -euo pipefail

EMACS_DIR="${HOME}/.emacs.d"
SPACEMACS_REPO="https://github.com/syl20bnr/spacemacs"

# Check if Emacs is installed
if ! command -v emacs &> /dev/null; then
    echo "Error: Emacs is not installed. Please install Emacs first."
    exit 1
fi

# Check if Spacemacs is already installed
if [ -d "${EMACS_DIR}/.git" ]; then
    if git -C "${EMACS_DIR}" remote get-url origin 2>/dev/null | grep -q "spacemacs"; then
        echo "Spacemacs is already installed."
        exit 0
    fi
fi

# Back up existing .emacs.d if it exists
if [ -d "${EMACS_DIR}" ]; then
    BACKUP_DIR="${EMACS_DIR}.backup.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing ${EMACS_DIR} to ${BACKUP_DIR}"
    mv "${EMACS_DIR}" "${BACKUP_DIR}"
fi

# Clone Spacemacs (develop branch)
echo "Installing Spacemacs (develop branch)..."
git clone -b develop "${SPACEMACS_REPO}" "${EMACS_DIR}"

echo "Spacemacs installed successfully!"
echo "Run 'emacs' to complete the initial setup."
