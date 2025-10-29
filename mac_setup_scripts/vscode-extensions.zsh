#!/bin/zsh

# =========================
# VS Code Extension Installer (v1.2 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"
LOGFILE="${LOG_DIR}/tany-vscode-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

EXTENSIONS=(
  "ms-vscode.cpptools"
  "ms-python.python"
  "ms-vscode-remote.remote-containers"
  "ms-azuretools.vscode-docker"
  "esbenp.prettier-vscode"
  "dbaeumer.vscode-eslint"
  "eamodio.gitlens"
  "mhutchie.git-graph"
  "github.vscode-pull-request-github"
)

print_summary() {
  log "This script will install VS Code extensions:"
  for ext in "${EXTENSIONS[@]}"; do echo "  - $ext"; done
  echo ""; log "Run with --dry-run to see what would be installed."
  log "Run with --undo to uninstall these extensions."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

if [[ "${1:-}" == "--undo" ]]; then
  log "🚀 Uninstalling VS Code extensions..."
  [[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
  for ext in "${EXTENSIONS[@]}"; do
    run code --uninstall-extension "$ext" || true
  done
  echo ""; echo "🎉 --- VS Code Extensions Uninstalled! --- 🎉"; exit 0
fi

log "🚀 Installing VS Code extensions..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary; log "Full log will be saved to $LOGFILE"

if ! command -v code >/dev/null 2>&1; then
  err "VS Code 'code' command not found in PATH."
  warn "Please open VS Code, run 'Cmd+Shift+P', and select 'Shell Command: Install \"code\" command in PATH'."
  exit 1
fi

for ext in "${EXTENSIONS[@]}"; do
  run code --install-extension "$ext" || true
done

echo ""; echo "🎉 --- VS Code Extensions Installed! --- 🎉"
