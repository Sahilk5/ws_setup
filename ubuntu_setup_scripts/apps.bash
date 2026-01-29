#!/bin/bash

# =========================
# GUI Apps Installer (v1.3 UBUNTU)
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_tany.sh"
require_ubuntu

LOGFILE="${HOME}/.tany-apps-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

print_summary() {
  log "This script will install GUI apps and CLIs via snap, apt, and flatpak:"
  echo "  - Docker Desktop (snap or apt)"
  echo "  - VS Code (snap or apt)"
  echo "  - Firefox (apt)"
  echo "  - Git (apt)"
  echo "  - AWS CLI (apt/pip)"
  echo "  - GitHub CLI (apt)"
  echo ""
  log "Run with --dry-run to see what would be installed."
  log "Run with --undo to uninstall these apps."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

if [[ "${1:-}" == "--undo" ]]; then
  run_s "$SCRIPT_DIR/uninstall-apps.bash $@"
  exit 0
fi

log "ðŸš€ Installing GUI apps & CLIs..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary
log "Full log will be saved to $LOGFILE"

log "Updating package lists..."
run_s "sudo apt-get update >/dev/null 2>&1 || true"

log "Installing development tools..."
dev_tools=(docker.io curl wget git build-essential python3-dev python3-pip)
apt_install "${dev_tools[@]}" || true

log "Installing other utilities..."
utilities=(firefox htop net-tools curl wget)
apt_install "${utilities[@]}" || true

log "Installing AWS CLI..."
if ! command -v aws >/dev/null 2>&1; then
  run_s "python3 -m pip install awscli --break-system-packages 2>/dev/null || sudo pip3 install awscli || true"
else
  ok "AWS CLI already installed."
fi

log "Installing GitHub CLI..."
if ! command -v gh >/dev/null 2>&1; then
  run_s "$CURL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /tmp/gh-key.gpg"
  run_s "sudo dd if=/tmp/gh-key.gpg of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
  run_s "echo 'deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null"
  run_s "sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y gh || true"
else
  ok "GitHub CLI already installed."
fi

log "Installing VS Code..."
if ! command -v code >/dev/null 2>&1; then
  run_s "$CURL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/vscode.gpg"
  run_s "sudo install -D -o root -g root -m 644 /tmp/vscode.gpg /etc/apt/keyrings/vscode.gpg"
  run_s "echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/vscode.gpg] https://packages.microsoft.com/repos/vscode stable main' | sudo tee /etc/apt/sources.list.d/vscode.list"
  run_s "sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y code || true"
else
  ok "VS Code already installed."
fi

echo ""
ok "Application installation complete!"
log "Full log saved to $LOGFILE"
