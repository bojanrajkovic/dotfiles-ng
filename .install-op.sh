#!/bin/sh
# Installs what chezmoi needs to read 1Password, before chezmoi reads the
# source state. Runs as hooks.read-source-state.pre (see .chezmoi.toml.tmpl),
# which fires on every chezmoi command, so the fast path must stay cheap.
#
# This is not a template; chezmoi data isn't available here.
#
# Both OSes: chezmoi reads 1Password with the official op, installed through
# mise. On Linux it calls op-real, so run `eval "$(op-real signin)"` first.
#
# Linux also gets op-forward and its `op` shim, which Claude sessions use for
# op-gate and op-mac (see with-op). chezmoi doesn't need them.
set -eu

# Keep in sync with dot_config/mise/config.toml.tmpl.
OP_VERSION="2.42.0"
# op-forward's apt/dnf repos were dead as of 2026-08-28, so this uses the
# GitHub release tarball. `op-forward update` self-updates afterwards.
OP_FORWARD_VERSION="1.1.0"

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN="$HOME/.local/bin"
MISE="$BIN/mise"
TOKEN_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/op-forward"

install_real_op() {
    if [ -x "$MISE" ] && "$MISE" which op >/dev/null 2>&1; then
        return 0
    fi

    if [ ! -x "$MISE" ]; then
        echo "Installing mise..." >&2
        curl -fsSL https://mise.run | sh
    fi
    echo "Installing 1Password CLI ${OP_VERSION} via mise..." >&2
    "$MISE" use -g "1password@${OP_VERSION}"
    "$MISE" reshim
}

install_linux() {
    # chezmoi manages op-real and with-op too; these copies only have to exist
    # before the first apply, and the contents match, so apply leaves them alone.
    mkdir -p "$BIN"
    chmod 700 "$BIN"
    for script in op-real with-op; do
        if [ ! -x "$BIN/$script" ]; then
            install -m 755 "$SOURCE_DIR/private_dot_local/private_bin/executable_$script" "$BIN/$script"
        fi
    done

    if [ -x "$BIN/op-forward" ] && [ -x "$BIN/op" ] && [ -f "$TOKEN_DIR/refresh.token" ]; then
        return 0
    fi

    mkdir -p "$TOKEN_DIR"

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

    if [ ! -f "$TOKEN_DIR/refresh.token" ]; then
        cat >&2 <<EOF
op-forward has no refresh token, so op-mac won't work here yet (chezmoi is fine).
The Mac runs one op-forward daemon per host. If $(hostname -s) isn't in
.chezmoidata.yaml's sshForwardedHosts yet, add it (with an opForwardPort)
and run \`chezmoi apply\` on the Mac; that starts its daemon and pushes the
token here. Otherwise, on the Mac, run:

    scp ~/Library/Caches/op-forward/$(hostname -s)/refresh.token $(hostname -s):.cache/op-forward/refresh.token

Then reconnect over SSH (so the 18340 RemoteForward is up).
EOF
    fi
}

case "$(uname -s)" in
    Linux) install_real_op; install_linux ;;
    Darwin) install_real_op ;;
    *) echo "Unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
