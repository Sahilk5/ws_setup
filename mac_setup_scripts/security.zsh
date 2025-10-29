#!/bin/zsh

# =========================
# Security & Identity Setup (v1.3 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"
LOGFILE="${LOG_DIR}/tany-security-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

print_summary() {
  log "This script will INTERACTIVELY help you:"
  echo "  1. Set your global Git name and email."
  echo "  2. Check for an SSH key (id_ed25519) and generate one if missing."
  echo "  3. Authenticate with GitHub CLI ('gh')."
  echo ""; log "This script is NOT idempotent and requires user input."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

log "🚀 Starting interactive security setup..."
print_summary; log "Full log will be saved to $LOGFILE"

echo ""; log "Configuring Git Identity..."
CURRENT_NAME=$(git config --global user.name || echo "")
CURRENT_EMAIL=$(git config --global user.email || echo "")

read "resp?Enter your FULL NAME for Git [$CURRENT_NAME]: "
if [[ -n "$resp" ]]; then
  git config --global user.name "$resp"; ok "Set Git user.name"
fi

read "resp?Enter your EMAIL for Git [$CURRENT_EMAIL]: "
email_to_use="${resp:-$CURRENT_EMAIL}"
if [[ -n "$resp" ]]; then
  git config --global user.email "$email_to_use"; ok "Set Git user.email"
fi

echo ""; log "Checking for SSH key..."
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
if [[ -f "$SSH_KEY_PATH.pub" ]]; then
  ok "Found SSH key at $SSH_KEY_PATH.pub"
else
  warn "No SSH key (id_ed25519) found."
  if confirm_prompt "Do you want to generate a new SSH key? (y/n)" "no"; then
    key_email="${email_to_use:-your_email@example.com}"
    ssh-keygen -t ed25519 -C "$key_email" -f "$SSH_KEY_PATH"
    ok "SSH key generated. Please add the public key to GitHub:"
    cat "$SSH_KEY_PATH.pub"
    command -v pbcopy >/dev/null && <"$SSH_KEY_PATH.pub" pbcopy && ok "Public key copied to clipboard."
  fi
fi

echo ""; log "Checking GitHub CLI auth..."
if command -v gh >/dev/null && gh auth status &>/dev/null; then
  ok "Already logged in to GitHub (gh)."
else
  warn "Not logged in to GitHub CLI."
  if command -v gh >/dev/null; then
    if confirm_prompt "Do you want to log in to GitHub CLI now? (y/n)" "yes"; then
      gh auth login
    fi
  else warn "'gh' command not found. Install with 'apps.zsh'."; fi
fi

echo ""; echo "🎉 --- Security Setup Complete! --- 🎉"
