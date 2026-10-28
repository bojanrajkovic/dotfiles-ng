#!/bin/sh
# Installs what chezmoi needs to read 1Password, before chezmoi reads the
# source state. Runs as hooks.read-source-state.pre (see .chezmoi.toml.tmpl),
# which fires on every chezmoi command, so the fast path must stay cheap.
#
# This is not a template; chezmoi data isn't available here.
#
# Linux: op is op-forward's shim, tunneled to the Mac over SSH
# (RemoteForward 18340, see private_dot_ssh/private_config.tmpl). chezmoi calls
# op-mac, which pins the shim to that tunnel even inside Claude sessions whose
# env routes op to op-gate.
#
# macOS: op is the real 1Password CLI, installed through mise.
set -eu

# Keep in sync with dot_config/mise/config.toml.tmpl.
OP_VERSION="v2.32.0"
# op-forward's apt/dnf repos were dead as of 2026-08-28, so this uses the
# GitHub release tarball. `op-forward update` self-updates afterwards.
OP_FORWARD_VERSION="1.1.0"

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
TOKEN_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/op-forward"

install_linux() {
    if [ -x "$BIN/op-forward" ] && [ -x "$BIN/op" ] && [ -x "$BIN/op-mac" ] \
        && [ -f "$TOKEN_DIR/refresh.token" ]; then
        return 0
    fi

    mkdir -p "$BIN" "$TOKEN_DIR"
    chmod 700 "$BIN"

    if [ ! -x "$BIN/op-forward" ]; then
        echo "Installing op-forward ${OP_FORWARD_VERSION}..." >&2
        case "$(uname -m)" in
            x86_64) arch=amd64 ;;
            aarch64) arch=arm64 ;;
            *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
        esac
        tmp="$(mktemp -d)"
        trap 'rm -rf "$tmp"' EXIT
        archive="op-forward_${OP_FORWARD_VERSION}_linux_${arch}.tar.gz"
        curl -fsSL "https://github.com/ekovshilovsky/op-forward/releases/download/v${OP_FORWARD_VERSION}/${archive}" -o "$tmp/$archive"
        tar -xzf "$tmp/$archive" -C "$tmp"
        install -m 755 "$tmp/op-forward" "$BIN/op-forward"
    fi

    if [ ! -x "$BIN/op" ]; then
        echo "Installing op-forward's op shim..." >&2
        "$BIN/op-forward" install
    fi

    # chezmoi manages op-mac too; this copy only has to exist before the first
    # apply, and the contents match, so apply leaves it alone.
    if [ ! -x "$BIN/op-mac" ]; then
        install -m 755 "$SOURCE_DIR/private_dot_local/private_bin/executable_op-mac" "$BIN/op-mac"
    fi

    if [ ! -f "$TOKEN_DIR/refresh.token" ]; then
        cat >&2 <<EOF
op-forward has no refresh token, so chezmoi can't read 1Password yet.
On the Mac, run:

    scp ~/Library/Caches/op-forward/refresh.token $(hostname):.cache/op-forward/refresh.token

Then reconnect over SSH (so the 18340 RemoteForward is up) and rerun chezmoi.
EOF
        exit 1
    fi
}

install_darwin() {
    MISE="$HOME/.local/bin/mise"
    if [ -x "$MISE" ] && [ -x "$HOME/.local/share/mise/shims/op" ]; then
        return 0
    fi

    if [ ! -x "$MISE" ]; then
        echo "Installing mise..." >&2
        curl -fsSL https://mise.run | sh
    fi
    echo "Installing 1Password CLI ${OP_VERSION} via mise..." >&2
    "$MISE" use -g "aqua:1password/cli@${OP_VERSION}"
    "$MISE" reshim
}

case "$(uname -s)" in
    Linux) install_linux ;;
    Darwin) install_darwin ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
