#!/usr/bin/env bash
# Install the Aria multi-dialect plugins into the local VS Code + Neovim
# config. Idempotent: replaces an existing symlink. Pass `vscode` or `nvim`
# to install only one; default installs both.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-all}"

install_vscode() {
    local dest_root
    if   [[ -d "$HOME/.vscode/extensions"          ]]; then dest_root="$HOME/.vscode/extensions"
    elif [[ -d "$HOME/.vscode-insiders/extensions" ]]; then dest_root="$HOME/.vscode-insiders/extensions"
    elif [[ -d "$HOME/.vscode-oss/extensions"      ]]; then dest_root="$HOME/.vscode-oss/extensions"
    else
        echo "no VS Code extensions dir found under \$HOME — install VS Code first" >&2
        return 1
    fi
    local link="$dest_root/aria-multi-0.1.0"
    rm -rf "$link"
    ln -s "$HERE/vscode" "$link"
    echo "[vscode] linked $link -> $HERE/vscode"
    echo "[vscode] reload VS Code (Cmd+Shift+P → 'Developer: Reload Window')"
}

install_nvim() {
    local dest_root="$HOME/.config/nvim/pack/aria/start"
    mkdir -p "$dest_root"
    local link="$dest_root/aria-multi"
    rm -rf "$link"
    ln -s "$HERE/nvim" "$link"
    echo "[nvim]   linked $link -> $HERE/nvim"
}

case "$TARGET" in
    vscode) install_vscode ;;
    nvim)   install_nvim ;;
    all)    install_vscode; install_nvim ;;
    *)      echo "usage: $0 [vscode|nvim|all]" >&2; exit 2 ;;
esac

echo
echo "test:  open editors/samples/strat_demo.aria in your editor — keywords"
echo "       like 'signal', 'strategy', 'when', and builtins ('sma', 'ema',"
echo "       'cross_up') should be colored. Try the other samples for the"
echo "       quantum / hdl / fin dialects."
