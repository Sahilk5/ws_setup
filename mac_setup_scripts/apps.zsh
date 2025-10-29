#!/bin/zsh

# =========================
# GUI Apps Installer (v1.3 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"
LOGFILE="${LOG_DIR}/tany-apps-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

print_summary() {
  log "This script will install GUI apps and CLIs using the Brewfile:"
  if [[ ! -f "$SCRIPT_DIR/Brewfile" ]]; then
    err "Brewfile not found at $SCRIPT_DIR/Brewfile. Exiting."
    exit 1
  fi
  grep -E '^(cask|brew)' "$SCRIPT_DIR/Brewfile" | sed 's/^cask /  - /; s/^brew /  - /; s/"//g'
  echo ""
  log "Run with --dry-run to see what would be installed."
  log "Run with --undo to uninstall these apps."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

if [[ "${1:-}" == "--undo" ]]; then
  run_s "$SCRIPT_DIR/uninstall-apps.zsh $@" # Pass along dry-run etc.
  exit 0
fi

log "🚀 Installing GUI apps & CLIs from Brewfile..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary; log "Full log will be saved to $LOGFILE"

log "Tapping cask-fonts (for Arc browser dependencies)..."
run brew tap homebrew/cask-fonts >/dev/null 2>&1 || true

# Prepare Brewfile (optionally filter problematic casks already installed outside Brew)
BREWFILE_SRC="$SCRIPT_DIR/Brewfile"
BREWFILE_USE="$BREWFILE_SRC"

if [[ $DRY_RUN -eq 1 ]]; then
  run brew bundle check --file="$BREWFILE_USE" || true # Check shows diff
else
  # Build a filtered Brewfile to skip docker-desktop if the app already exists
  tmp_brewfile=$(mktemp)
  while IFS= read -r line; do
    case "$line" in
      (cask\ "docker-desktop"*)
        if brew list --cask docker-desktop >/dev/null 2>&1; then
          echo "$line" >> "$tmp_brewfile"
        elif [[ -d "/Applications/Docker.app" ]]; then
          warn "Skipping docker-desktop: /Applications/Docker.app already exists (not Homebrew-managed)."
          warn "To have Homebrew manage Docker, move Docker.app to Trash first, then re-run."
          # Do not add to Brewfile; skip adoption to avoid xattr permission errors
        else
          echo "$line" >> "$tmp_brewfile"
        fi
        ;;
      (*)
        echo "$line" >> "$tmp_brewfile"
        ;;
    esac
  done < "$BREWFILE_SRC"
  BREWFILE_USE="$tmp_brewfile"
  run brew bundle --file="$BREWFILE_USE"
fi

echo ""; echo "🎉 --- App Installation Complete! --- 🎉"
warn "Note: 'gh' and 'awscli' require you to log in."
warn "Run 'gh auth login' and 'aws configure sso' (or 'aws configure')."
