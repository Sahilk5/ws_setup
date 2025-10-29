#!/bin/zsh

# =========================
# Undo macOS Defaults (v1.3 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"
LOGFILE="${LOG_DIR}/tany-undo-defaults-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

print_summary() {
  log "This script will revert macOS settings in Finder, Dock,"
  log "and Keyboard to their approximate factory defaults."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

log "🚀 Reverting macOS defaults..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary; log "Full log will be saved to $LOGFILE"

if [[ $DRY_RUN -eq 0 ]]; then
  if ! confirm_prompt "Are you sure you want to revert these settings? (y/n)" "no"; then
    log "Cancelled."; exit 0
  fi
fi

log "Reverting Keyboard..."
run_defaults write -g KeyRepeat -int 6
run_defaults write -g InitialKeyRepeat -int 25

log "Reverting Finder..."
run_defaults write NSGlobalDomain AppleShowAllExtensions -bool false
run_defaults write com.apple.finder ShowPathbar -bool false
run_defaults write com.apple.finder FXDefaultSearchScope -string "SCsp"
run_defaults write com.apple.finder _FXSortFoldersFirst -bool false
run_defaults write com.apple.finder AppleShowAllFiles -bool false

log "Reverting Dock..."
run_defaults write com.apple.dock autohide -bool false
run_defaults write com.apple.dock tilesize -int 64
run_defaults delete com.apple.dock autohide-delay
run_defaults write com.apple.dock show-recents -bool true

log "Reverting miscellaneous UI settings..."
run_defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode
run_defaults delete NSGlobalDomain NSNavPanelExpandedStateForSaveMode2
run_defaults delete com.apple.screencapture location
run_defaults delete com.apple.screencapture type
run_defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

log "Restarting Dock and Finder to apply changes..."
run killall Dock 2>/dev/null || true
run killall Finder 2>/dev/null || true

echo ""; echo "🎉 --- macOS Defaults Reverted! --- 🎉"
log "Some changes may require a full logout/restart."
