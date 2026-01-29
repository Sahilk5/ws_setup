#!/bin/bash

# =========================
# tany workspace uninstaller (v1.3 UBUNTU)
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_tany.sh"
require_ubuntu

LOGFILE="${HOME}/.tany-uninstall-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

ZSHRC="$HOME/.zshrc"
ZSH_BLOCK_BEGIN="# >>> tany-setup BEGIN >>>"
ZSH_BLOCK_END="# <<< tany-setup END <<<"

echo ""
warn "This script will UNINSTALL all packages and configs from 'setup_ws_ubuntu.bash'."
warn "This includes:"
echo "  - APT packages (eza, bat, nvim, tmux, zoxide, etc.)"
echo "  - Oh My Zsh, Powerlevel10k, and Zsh plugins"
echo "  - Config files (~/.tmux.conf, ~/.config/nvim, etc.)"
echo "  - All additions inside BEGIN/END markers in ~/.zshrc"
echo ""
warn "It will NOT uninstall asdf or system dependencies."
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
  warn "DRY RUN MODE: No changes will be made."
else
  if ! confirm_prompt "Are you sure you want to proceed? (y/n)" "no"; then
    log "Uninstall cancelled."; exit 0
  fi
fi

log "Full log will be saved to $LOGFILE"

log "Uninstalling packages..."
packages=(bat ripgrep fd-find btop tmux lazygit direnv neovim zsh)
for pkg in "${packages[@]}"; do
  run sudo apt-get remove -y "$pkg" 2>/dev/null || true
done
ok "Packages removal attempted."

log "Removing config files (backups will be created)..."
backup_then_rm "$HOME/.tmux.conf"
backup_then_rm "$HOME/.p10k.zsh"
backup_then_rm "$HOME/.config/nvim"
backup_then_rm "$HOME/.config/ripgrep"
ok "Config files removed."

log "Uninstalling Oh My Zsh..."
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  run_s "bash $HOME/.oh-my-zsh/tools/uninstall.sh --unattended || true"
  run rm -f "$HOME/.zshrc.pre-oh-my-zsh" || true
fi
ok "Oh My Zsh uninstalled."

log "Cleaning shell configs..."
if [[ -f "$ZSHRC" ]]; then
  run_s "perl -0777 -i -pe \"s/\\n?$ZSH_BLOCK_BEGIN.*?$ZSH_BLOCK_END\\n?//s\" \"$ZSHRC\""
  run_s "perl -i -pe 's/^ZSH_THEME=.*\\n?//g' \"$ZSHRC\" 2>/dev/null || true"
  run_s "perl -i -pe 's/^source \\\$ZSH\\/oh-my-zsh\\.sh\\n?//g' \"$ZSHRC\" 2>/dev/null || true"
  ok "~/.zshrc cleaned."
fi

log "Reverting Git config..."
run git config --global --unset core.editor || true
run git config --global --unset init.defaultBranch || true
run git config --global --unset pull.rebase || true
run git config --global --unset fetch.prune || true
run git config --global --unset diff.colorMoved || true
run git config --global --unset diff.algorithm || true
run git config --global --unset fetch.parallel || true
run git config --global --unset core.pager || true
run git config --global --unset interactive.diffFilter || true
run git config --global --unset delta.features || true
run git config --global --unset delta.side-by-side || true
ok "Git config reverted."

echo ""
ok "Uninstallation complete. Check $LOGFILE for details."
