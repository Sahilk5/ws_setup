#!/bin/bash

# =========================
# VS Code Extensions Installer (v1.3 UBUNTU)
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_tany.sh"
require_ubuntu

LOGFILE="${HOME}/.tany-vscode-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

# List of recommended VS Code extensions
EXTENSIONS=(
  "ms-vscode.cpptools"
  "ms-vscode.vscode-typescript-next"
  "esbenp.prettier-vscode"
  "dbaeumer.vscode-eslint"
  "github.copilot"
  "eamodio.gitlens"
  "ms-azuretools.vscode-docker"
  "github.github-vscode-theme"
  "ms-python.python"
  "ms-python.vscode-pylance"
)

print_summary() {
  log "This script will install VS Code extensions:"
  for ext in "${EXTENSIONS[@]}"; do
    echo "  - $ext"
  done
  echo ""
  log "Run with --dry-run to see what would be installed."
  log "Run with --undo to uninstall these extensions."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

if [[ "${1:-}" == "--undo" ]]; then
  log "ðŸ—‘ï¸  Uninstalling VS Code extensions..."
  [[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
  print_summary
  for ext in "${EXTENSIONS[@]}"; do
    run code --uninstall-extension "$ext" 2>/dev/null || true
  done
  ok "Extensions uninstalled."
  exit 0
fi

log "ðŸš€ Installing VS Code extensions..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary
log "Full log will be saved to $LOGFILE"

if ! command -v code >/dev/null 2>&1; then
  err "VS Code not found. Install it first: ./tany install apps"
  exit 1
fi

for ext in "${EXTENSIONS[@]}"; do
  run code --install-extension "$ext" 2>/dev/null || warn "Failed to install $ext"
done

echo ""
ok "VS Code extensions installation complete!"
log "Full log saved to $LOGFILE"
