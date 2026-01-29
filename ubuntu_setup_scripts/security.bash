#!/bin/bash

# =========================
# Security & Identity Setup (v1.3 UBUNTU)
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_tany.sh"
require_ubuntu

LOGFILE="${HOME}/.tany-security-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

print_summary() {
  log "This script will INTERACTIVELY help you:"
  echo "  1. Set your global Git name and email."
  echo "  2. Check for an SSH key (id_ed25519) and generate one if missing."
  echo "  3. Authenticate with GitHub CLI ('gh')."
  echo ""
  log "This script is NOT idempotent and requires user input."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

log "ðŸš€ Starting interactive security setup..."
print_summary
log "Full log will be saved to $LOGFILE"

echo ""
log "Configuring Git Identity..."
CURRENT_NAME=$(git config --global user.name || echo "")
CURRENT_EMAIL=$(git config --global user.email || echo "")

read -p "Enter your FULL NAME for Git [$CURRENT_NAME]: " resp
if [[ -n "$resp" ]]; then
  git config --global user.name "$resp"
  ok "Set Git user.name"
fi

read -p "Enter your EMAIL for Git [$CURRENT_EMAIL]: " resp
email_to_use="${resp:-$CURRENT_EMAIL}"
if [[ -n "$resp" ]]; then
  git config --global user.email "$email_to_use"
  ok "Set Git user.email"
fi

echo ""
log "Checking for SSH key..."
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
if [[ -f "$SSH_KEY_PATH.pub" ]]; then
  ok "Found SSH key at $SSH_KEY_PATH.pub"
  echo ""
  echo "Public key:"
  cat "$SSH_KEY_PATH.pub"
else
  if confirm_prompt "SSH key not found. Generate a new Ed25519 key? (y/n)" "yes"; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "$(whoami)@$(hostname)"
    ok "SSH key generated at $SSH_KEY_PATH"
    echo ""
    echo "Public key:"
    cat "$SSH_KEY_PATH.pub"
    echo ""
    warn "Add this key to GitHub: https://github.com/settings/keys"
  fi
fi

echo ""
if command -v gh >/dev/null 2>&1; then
  log "GitHub CLI found. Authenticating..."
  if ! gh auth status >/dev/null 2>&1; then
    if confirm_prompt "Authenticate with GitHub CLI? (y/n)" "yes"; then
      gh auth login
      ok "GitHub CLI authenticated."
    fi
  else
    ok "GitHub CLI is already authenticated."
  fi
else
  warn "GitHub CLI ('gh') not found. Install it first: ./tany install apps"
fi

echo ""
ok "Security setup complete!"
log "Full log saved to $LOGFILE"
