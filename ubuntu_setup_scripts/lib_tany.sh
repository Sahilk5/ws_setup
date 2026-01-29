#!/bin/bash

# =========================
# tany workspace helper lib (v1.3 UBUNTU)
# =========================

# --- Safety & UX ---
set -e -u -o pipefail

# Normalise PATH
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# Error trap
trap 'echo "âŒ Error on line $LINENO in $0"; exit 1' ERR

# --- Logging ---
log()  { echo -e "\033[36m==>\033[0m $*"; }
ok()   { echo -e "\033[32mâœ“\033[0m  $*"; }
warn() { echo -e "\033[33m!\033[0m  $*"; }
err()  { echo -e "\033[31mâœ—\033[0m  $*"; }

# --- System Checks ---
require_ubuntu() {
  if ! grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
    err "This script is Ubuntu/Debian-only."
    exit 1
  fi
}

# --- File/Config Helpers ---
uuid() { date +%s$$; }

# Appends a line once to a file, only if it doesn't already exist
append_once() {
  local line="$1" file="$2"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    if [[ -f "$file" ]] && grep -Fqx -- "$line" "$file" 2>/dev/null; then
      echo -e "\033[33m(dry-run)\033[0m keep existing line in $file"
    else
      echo -e "\033[33m(dry-run)\033[0m append '$line' to $file"
    fi
    return 0
  fi
  [[ -f "$file" ]] || : > "$file"
  grep -Fqx -- "$line" "$file" 2>/dev/null || printf "%s\n" "$line" >> "$file"
}

# Replace-or-append helper (safe, cross-platform)
replace_or_append() {
  local regex="$1" repl="$2" file="$3"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m replace_or_append '$regex' â†’ '$repl' in $file"
    return 0
  fi
  [[ -f "$file" ]] || : > "$file"
  if grep -Eq "$regex" "$file" 2>/dev/null; then
    local perl_regex="${regex//\//\\/}"
    local perl_repl="${repl//\//\\/}"
    perl -i -pe "s/$perl_regex/$perl_repl/" "$file"
  else
    printf "\n%s\n" "$repl" >> "$file"
  fi
}

# Idempotently replaces a block, or creates it if it doesn't exist
replace_block() {
  local file="$1" begin="$2" end="$3" content="$4"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m replace block [$begin ... $end] in $file"
    return 0
  fi
  [[ -f "$file" ]] || : > "$file"
  
  local tmp; tmp="$(mktemp)"
  TANY_BEGIN="$begin" TANY_END="$end" TANY_CONTENT="$content" python3 - "$file" "$tmp" <<'PY' || {
import os, sys, re
src = sys.argv[1]
dst = sys.argv[2]
begin = os.environ["TANY_BEGIN"]
end = os.environ["TANY_END"]
content = os.environ["TANY_CONTENT"]
with open(src, "r", encoding="utf-8") as fh:
    data = fh.read()
pattern = re.compile(rf"\n?{re.escape(begin)}.*?{re.escape(end)}\n?", re.S)
replacement = f"\n{begin}\n{content}\n{end}\n"
if pattern.search(data):
    data = pattern.sub(replacement, data)
else:
    if data and not data.endswith("\n"):
        data += "\n"
    data += replacement.lstrip("\n")
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(data)
PY
    rm -f "$tmp"
    err "Failed to update block in $file"
    return 1
  }
  mv "$tmp" "$file"
  ok "Updated block in $file"
}

# Add a plugin to an Oh My Zsh plugins=() list idempotently
add_zsh_plugin() {
  local file="$1"
  local plugin="$2"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m add plugin '$plugin' to $file"
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  awk -v plugin="$plugin" '
    /^[[:space:]]*plugins=\(/ {
      line = $0
      line_end = line; sub(/\)\s*$/, "", line_end)
      if (line_end ~ "(^|[[:space:]])" plugin "([[:space:]]|$)") { print; next }
      if (sub(/\)\s*$/, " " plugin ")", line)) { print line; next }
      in_plugins=1; seen=0
    }
    in_plugins {
      if ($0 ~ "(^|[[:space:]])" plugin "([[:space:]]|$)") { seen=1 }
    }
    in_plugins && /^[[:space:]]*\)/ {
      if (!seen) { print "  " plugin }
      in_plugins=0; seen=0
    }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# Deduplicate plugin entries inside plugins=(...) in a .zshrc file
dedup_zsh_plugins() {
  local file="$1"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m dedup plugins in $file"
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  awk '
    function flush(collected,   n,i,tok,seen,out) {
      n=split(collected, arr, /[[:space:]]+/)
      delete seen
      out = "plugins=("
      for (i=1; i<=n; i++) {
        tok=arr[i]; if (tok=="") continue
        if (!(tok in seen)) { out = out (out=="plugins=(" ? "" : " ") tok; seen[tok]=1 }
      }
      print out ")"
    }
    /^[[:space:]]*plugins=\(/ {
      in_block=1; collected=""
      line=$0
      sub(/^[[:space:]]*plugins=\(/, "", line)
      if (line ~ /\)/) {
        sub(/\).*/, "", line); collected=collected " " line
        flush(collected); in_block=0; collected=""; next
      }
      if (length(line) > 0) collected=collected " " line
      next
    }
    in_block && /^[[:space:]]*\)/ { flush(collected); in_block=0; collected=""; next }
    in_block { collected=collected " " $0; next }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

# Prompt helper with sensible defaults
confirm_prompt() {
  local prompt="$1"
  local default="${2:-no}"
  local default_lower="${default,,}"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    warn "(dry-run) auto-answering '${prompt}' with ${default_lower}"
    [[ "$default_lower" == "y" || "$default_lower" == "yes" ]]
    return
  fi

  local auto_mode="ask"
  if _tany_truthy "${TANY_ASSUME_NO:-}"; then
    auto_mode="no"
  elif _tany_truthy "${TANY_ASSUME_YES:-}"; then
    auto_mode="yes"
  fi
  if [[ "$auto_mode" == "ask" && ! -t 0 ]]; then
    auto_mode="$default_lower"
    warn "No interactive terminal detected; defaulting to '$default_lower' for prompt: $prompt"
  fi
  case "$auto_mode" in
    yes|y|true|1|on)
      log "Auto-confirmed prompt: $prompt"; return 0 ;;
    no|n|false|0|off)
      log "Auto-declined prompt: $prompt"; return 1 ;;
  esac

  local suffix="[y/N]"
  if [[ "$default_lower" == "y" || "$default_lower" == "yes" ]]; then
    suffix="[Y/n]"
  fi

  local reply
  while true; do
    read -p "${prompt} ${suffix} " reply
    reply="${reply:-$default_lower}"
    reply="${reply,,}"
    case "$reply" in
      y|yes) return 0 ;;
      n|no)  return 1 ;;
      *) echo "Please answer yes or no."; ;;
    esac
  done
}

# Safely backs up a file/dir before removing it
backup_then_rm() {
  local path="$1"
  if [[ -e "$path" ]]; then
    if [[ ${DRY_RUN:-0} -eq 1 ]]; then
      echo -e "\033[33m(dry-run)\033[0m would backup and remove $path"
      return 0
    fi
    local bak_date; bak_date=$(date +%Y%m%d-%H%M%S)
    local bak="${path}.bak.${bak_date}"
    log "Backing up $path to $bak..."
    mv "$path" "$bak"
    ok "Backed up $path. Old version is at $bak."
  fi
}

# Writes content to a file atomically via a temp file
atomic_write() {
  local dest="$1" payload="$2" tmp
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m write payload to $dest"
    return 0
  fi
  tmp="$(mktemp)"
  printf "%s\n" "$payload" > "$tmp"
  mv "$tmp" "$dest"
}

# Helper for confirm_prompt truthy envs
_tany_truthy() {
  case "$1" in
    1|y|Y|yes|YES|true|TRUE|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

# --- Network Resiliency ---
CURL="curl --fail --location --retry 3 --retry-connrefused --retry-delay 2"
git_retry() {
  local ret=0
  for i in {1..3}; do
    git "$@"; ret=$?
    (( ret == 0 )) && return 0
    (( i < 3 )) && { warn "Git command failed. Retrying ($i/3)..."; sleep 2; }
  done
  err "Git command failed after 3 retries: $*"
  return $ret
}

# --- Dry Run ---
: "${DRY_RUN:=0}"

# run() takes args, run_s() takes a string to eval
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m $*"
  else
    "$@"
  fi
}

run_s() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m $1"
  else
    eval "$1"
  fi
}

run_git_config() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m git config --global $1 \"$2\""
  else
    git config --global "$1" "$2"
  fi
}

# APT package installation helper
apt_install() {
  if [[ $DRY_RUN -eq 1 ]]; then
    echo -e "\033[33m(dry-run)\033[0m apt-get install -y $*"
    return 0
  fi
  # Attempt to install without prompting
  if command -v apt-get >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive sudo apt-get install -y "$@" 2>&1 || {
      warn "apt-get install failed. Trying alternative..."
      sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y "$@" || return 1
    }
  else
    err "apt-get not found"
    return 1
  fi
}
