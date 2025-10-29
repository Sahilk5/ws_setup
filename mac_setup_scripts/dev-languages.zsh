#!/bin/zsh

# =========================
# Language Runtime Installer (v1.3 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOG_DIR="$SCRIPT_DIR/../logs"
mkdir -p "$LOG_DIR"
LOGFILE="${LOG_DIR}/tany-languages-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

PLUGINS=(nodejs python java golang)
NODE_VERSION="20.17.0"
PYTHON_VERSION="3.12.6"
SET_GLOBALS=1

print_summary() {
  log "This script will use 'asdf' to install language runtimes:"
  echo "  - Add plugins: ${PLUGINS[@]}"
  echo "  - Install NodeJS $NODE_VERSION"
  echo "  - Install Python $PYTHON_VERSION"
  [[ $SET_GLOBALS -eq 1 ]] && echo "  - Set Node & Python as global defaults"
  echo ""; log "Run with --dry-run to see what would be installed."
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; exit 0
fi

log "🚀 Installing language runtimes via asdf..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary; log "Full log will be saved to $LOGFILE"

if [[ ! -f "$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh" ]]; then
  err "asdf not found. Run setup_ws_mac.zsh first (or 'brew install asdf')."
  exit 1
fi

log "Sourcing asdf..."; . "$(brew --prefix asdf)/libexec/asdf.sh"

if [[ $DRY_RUN -eq 0 ]]; then
  if ! confirm_prompt "Proceed with installation? (y/n)" "yes"; then
    log "Cancelled."; exit 0
  fi
else
  confirm_prompt "Proceed with installation? (y/n)" "yes" >/dev/null
fi

if [[ $DRY_RUN -eq 0 ]]; then
  :
fi

log "Adding asdf plugins..."
PLUGIN_LIST_CMD=""
if asdf plugin list >/dev/null 2>&1; then
  PLUGIN_LIST_CMD="asdf plugin list"
elif asdf plugin-list >/dev/null 2>&1; then
  PLUGIN_LIST_CMD="asdf plugin-list"
else
  err "Unable to list asdf plugins."
  exit 1
fi

for plugin in "${PLUGINS[@]}"; do
  if ! eval "$PLUGIN_LIST_CMD" | grep -q "^$plugin$"; then
    run asdf plugin add $plugin
    if [[ "$plugin" == "nodejs" ]]; then
      KEYRING_SCRIPT="${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/nodejs/bin/import-release-team-keyring"
      if [[ -x "$KEYRING_SCRIPT" ]]; then
        run_s "bash -c '$KEYRING_SCRIPT' || true"
      else
        warn "NodeJS keyring import script not found; skipping."
      fi
    fi
  else ok "$plugin plugin already added."; fi
done

log "Installing Node $NODE_VERSION..."
run asdf install nodejs $NODE_VERSION || true

log "Installing Python $PYTHON_VERSION..."
run asdf install python $PYTHON_VERSION || true

set_tool_version() {
  local name="$1" version="$2" file="$HOME/.tool-versions"
  if [[ $DRY_RUN -eq 1 ]]; then
    warn "(dry-run) set $name $version in ~/.tool-versions"
    return 0
  fi
  touch "$file"
  if grep -q "^$name " "$file" 2>/dev/null; then
    perl -i -pe "s/^$name .*$/$name $version/" "$file"
  else
    printf "%s %s\n" "$name" "$version" >> "$file"
  fi
}

if [[ $SET_GLOBALS -eq 1 ]]; then
  log "Setting global versions..."
  set_tool_version "nodejs" "$NODE_VERSION"
  set_tool_version "python" "$PYTHON_VERSION"
  run asdf reshim nodejs || true
  run asdf reshim python || true
fi

log "Running Homebrew cleanup..."
run brew cleanup -s || true

echo ""; echo "🎉 --- Language Runtimes Installed! --- 🎉"
log "Relaunch your shell to use the new global versions."
