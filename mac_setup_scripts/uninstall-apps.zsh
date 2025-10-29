#!/bin/zsh

# =========================
# GUI Apps Uninstaller (v1.2 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"
LOGFILE="${LOG_DIR}/tany-uninstall-apps-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

ZAP_APPS=(docker postman tableplus utm arc firefox rectangle raycast alt-tab)
CLIS=(awscli gh)

print_summary() {
  if [[ ! -f "$SCRIPT_DIR/Brewfile" ]]; then
    err "Brewfile not found at $SCRIPT_DIR/Brewfile. Exiting."
    exit 1
  fi
  log "This script will UNINSTALL all apps from the Brewfile."
  log "It will also --zap (remove all settings) for:"
  for app in "${ZAP_APPS[@]}"; do echo "  - $app"; done
  echo ""
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

log "🚀 Uninstalling GUI apps & CLIs from Brewfile..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary; log "Full log will be saved to $LOGFILE"

if [[ $DRY_RUN -eq 0 ]]; then
  if ! confirm_prompt "Are you sure you want to uninstall and zap these apps? (y/n)" "no"; then
    log "Cancelled."; exit 0
  fi
fi

log "Zapping common apps (removes settings)..."
run brew uninstall --zap --cask "${ZAP_APPS[@]}" || true

log "Uninstalling CLIs..."
run brew uninstall "${CLIS[@]}" || true

log "Cleaning up any remaining Brewfile apps..."
run brew bundle cleanup --file="$SCRIPT_DIR/Brewfile" --force

echo ""; echo "🎉 --- App Uninstallation Complete! --- 🎉"
