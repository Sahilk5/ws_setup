#!/bin/zsh

# =========================
# macOS Defaults (v1.3 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"
LOGFILE="${LOG_DIR}/tany-defaults-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

print_summary() {
  log "This script will apply opinionated macOS system defaults for:"
  echo "  - Keyboard: Faster key repeat"
  echo "  - Finder: Show all files, extensions, path bar, folders on top"
  echo "  - Dock: Auto-hide (instant), size 64px, remove recents, disable hot corners"
  echo "  - UI: Expand save panels, set screenshot location, disable natural scroll"
  echo ""; log "Run with --dry-run to see what would be changed."
  log "Run with --undo to revert to factory defaults."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

if [[ "${1:-}" == "--undo" ]]; then
  run_s "$SCRIPT_DIR/undo-macos-defaults.zsh $@" # Pass dry-run etc.
  exit 0
fi

log "🚀 Applying macOS defaults..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary; log "Full log will be saved to $LOGFILE"

if [[ $DRY_RUN -eq 0 ]]; then
  if ! confirm_prompt "Are you sure you want to apply these INVASIVE changes? (y/n)" "yes"; then
    log "Cancelled."; exit 0
  fi
fi

log "Configuring Keyboard..."
run_defaults write -g KeyRepeat -int 2
run_defaults write -g InitialKeyRepeat -int 15

log "Configuring Finder..."
run_defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run_defaults write com.apple.finder ShowPathbar -bool true
run_defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
run_defaults write com.apple.finder _FXSortFoldersFirst -bool true
run_defaults write com.apple.finder AppleShowAllFiles -bool true

log "Configuring Dock..."
run_defaults write com.apple.dock autohide -bool true
run_defaults write com.apple.dock tilesize -int 64
run_defaults write com.apple.dock autohide-delay -float 0
run_defaults write com.apple.dock show-recents -bool false
run_defaults write com.apple.dock wvous-tl-corner -int 0
run_defaults write com.apple.dock wvous-tr-corner -int 0
run_defaults write com.apple.dock wvous-bl-corner -int 0
run_defaults write com.apple.dock wvous-br-corner -int 0

log "Configuring miscellaneous UI settings..."
run_defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
run_defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
run mkdir -p "$HOME/Pictures/Screenshots"
run_defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"
run_defaults write com.apple.screencapture type -string "png"
run_defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

log "Restarting Dock and Finder to apply changes..."
run killall Dock 2>/dev/null || true
run killall Finder 2>/dev/null || true

echo ""; echo "🎉 --- macOS Defaults Applied! --- 🎉"
log "Some changes may require a full logout/restart."
