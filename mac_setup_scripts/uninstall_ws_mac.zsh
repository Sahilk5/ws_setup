#!/bin/zsh

# =========================
# tany workspace uninstaller (v1.3 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOGFILE="${HOME}/.tany-uninstall-$(/bin/date +%Y%m%d 2>/dev/null || date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

ZSHRC="$HOME/.zshrc"; ZPROFILE="$HOME/.zprofile"
ZSH_BLOCK_BEGIN="# >>> tany-setup BEGIN >>>"; ZSH_BLOCK_END="# <<< tany-setup END <<<"
ZPROFILE_BLOCK_BEGIN="# >>> tany-setup-zprofile BEGIN >>>"; ZPROFILE_BLOCK_END="# <<< tany-setup-zprofile END <<<"

echo ""; warn "This script will UNINSTALL all packages and configs from 'setup_ws_mac.zsh'."
warn "This includes:"; echo "  - Brew packages (eza, bat, nvim, tmux, zoxide, etc.)"
echo "  - Oh My Zsh, Powerlevel10k, and Zsh plugins"
echo "  - Config files (~/.tmux.conf, ~/.p10k.zsh, ~/.config/nvim, etc.)"
echo "  - All additions inside BEGIN/END markers in ~/.zshrc and ~/.zprofile"
echo ""; warn "It will NOT uninstall Homebrew itself."; echo ""

if [[ $DRY_RUN -eq 1 ]]; then warn "DRY RUN MODE: No changes will be made."; else
  if ! confirm_prompt "Are you sure you want to proceed? (y/n)" "no"; then
    log "Uninstall cancelled."; exit 0
  fi
fi

log "Full log will be saved to $LOGFILE"

log "Uninstalling Homebrew packages..."
formulas=(bat eza fzf btop neovim ripgrep fd lazygit jq tmux tlrc zoxide direnv git-delta asdf)
casks=(iterm2 font-hack-nerd-font)
run brew uninstall "${formulas[@]}" || true
run brew uninstall --cask "${casks[@]}" || true
ok "Packages uninstalled."

log "Removing config files (backups will be created)..."
backup_then_rm "$HOME/.tmux.conf"; backup_then_rm "$HOME/.p10k.zsh"
backup_then_rm "$HOME/.config/nvim"; backup_then_rm "$HOME/.config/ripgrep"
# Remove iTerm2 dynamic profile outright to avoid lingering duplicates
run rm -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles/tany.json" || true
ok "Config files removed."

log "Uninstalling Oh My Zsh..."
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  run_s "(cd \"$HOME/.oh-my-zsh/tools\" && sh uninstall.sh --unattended) || true"
  run rm -f "$HOME/.zshrc.pre-oh-my-zsh"
fi
ok "Oh My Zsh uninstalled."

log "Cleaning shell configs..."
if [[ -f "$ZSHRC" ]]; then
  run_s "perl -0777 -i -pe \"s/\\n?$ZSH_BLOCK_BEGIN.*?$ZSH_BLOCK_END\\n?//s\" \"$ZSHRC\""
  run_s "perl -i -pe 's/^ZSH_THEME=\"powerlevel10k\/powerlevel10k\"\\n?//g' \"$ZSHRC\" 2>/dev/null || true"
  run_s "perl -i -pe 's/^source \\\$ZSH\/oh-my-zsh\.sh\\n?//g' \"$ZSHRC\" 2>/dev/null || true"
  ok "~/.zshrc cleaned."
fi
if [[ -f "$ZPROFILE" ]]; then
  run_s "perl -0777 -i -pe \"s/\\n?$ZPROFILE_BLOCK_BEGIN.*?$ZPROFILE_BLOCK_END\\n?//s\" \"$ZPROFILE\""
  ok "~/.zprofile cleaned."
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
run git config --global --unset delta.navigate || true
run git config --global --unset delta.line-numbers || true
ok "Git config reverted."

echo ""; echo "🎉 --- UNINSTALL COMPLETE! --- 🎉"
log "Restart your terminal for all changes to take effect."
