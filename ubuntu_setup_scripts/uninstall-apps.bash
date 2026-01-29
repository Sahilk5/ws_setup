#!/bin/bash

# =========================
# GUI Apps Uninstaller (v1.3 UBUNTU)
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_tany.sh"
require_ubuntu

LOGFILE="${HOME}/.tany-apps-uninstall-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

echo ""
warn "This script will uninstall GUI applications and CLIs installed by apps.bash"
echo ""

if [[ $DRY_RUN -eq 1 ]]; then
  warn "DRY RUN MODE: No changes will be made."
else
  if ! confirm_prompt "Are you sure? (y/n)" "no"; then
    log "Uninstall cancelled."; exit 0
  fi
fi

log "Full log will be saved to $LOGFILE"

log "Removing applications..."
apps=(docker.io code firefox awscli gh)
for app in "${apps[@]}"; do
  run sudo apt-get remove -y "$app" 2>/dev/null || true
done
ok "Applications removal attempted."

echo ""
ok "Application uninstallation complete!"
log "Full log saved to $LOGFILE"
