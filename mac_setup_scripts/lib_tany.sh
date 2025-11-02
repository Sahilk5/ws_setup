#!/bin/zsh

# =========================
# tany workspace helper lib (v1.3 FINAL)
# =========================

# --- Safety & UX ---
# Use zsh-safe set options
set -e -u
set -o pipefail
# Normalise PATH for sandboxed shells that may lack standard locations
typeset -gU path PATH
path=(/usr/local/bin /opt/homebrew/bin /usr/bin /bin /usr/sbin /sbin $path)

# Use zsh-specific TRAPZERR function that exits
TRAPZERR() {
  print -P "%F{red}✗%f  Error on line $LINENO in $0";
  exit 1 # Guarantee exit
}
# Defining the function is sufficient in zsh

# --- Logging ---
log()  { print -P "%F{cyan}==>%f $*"; }
ok()   { print -P "%F{green}✓%f  $*"; }
warn() { print -P "%F{yellow}!%f  $*"; }
err()  { print -P "%F{red}✗%f  $*"; }

# --- System Checks ---
require_macos() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    err "This script is macOS-only."
    exit 1
  fi
}

# --- File/Config Helpers ---
uuid() { command -v uuidgen >/dev/null && uuidgen || date +%s$$; }

# Appends a line once to a file, only if it doesn't already exist
append_once() {
  local line="$1" file="$2"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    if [[ -f "$file" ]] && grep -Fqx -- "$line" "$file" 2>/dev/null; then
      print -P "%F{yellow}(dry-run)%f keep existing line in $file"
    else
      print -P "%F{yellow}(dry-run)%f append '$line' to $file"
    fi
    return 0
  fi
  [[ -f "$file" ]] || : > "$file" # Create file if it doesn't exist
  grep -Fqx -- "$line" "$file" 2>/dev/null || printf "%s\n" "$line" >> "$file"
}

# Replace-or-append helper (safe, cross-platform)
replace_or_append() {
  local regex="$1" repl="$2" file="$3"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    print -P "%F{yellow}(dry-run)%f replace_or_append '$regex' → '$repl' in $file"
    return 0
  fi
  [[ -f "$file" ]] || : > "$file" # Create file if it doesn't exist
  if grep -Eq "$regex" "$file" 2>/dev/null; then
    local perl_regex="${regex//\//\\/}"
    local perl_repl="${repl//\//\\/}"
    perl -i -pe "s/$perl_regex/$perl_repl/" "$file"
  else
    printf "\n%s\n" "$repl" >> "$file"
  fi
}

# Appends a block of text, wrapped in markers, only if markers don't exist
ensure_block() {
  local file="$1" begin_marker="$2" end_marker="$3"
  local content="$4"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    print -P "%F{yellow}(dry-run)%f ensure block [$begin_marker ... $end_marker] in $file"
    return 0
  fi
  if ! grep -Fqx -- "$begin_marker" "$file" 2>/dev/null; then
    {
      echo ""
      echo "$begin_marker"
      printf "%s\n" "$content"
      echo "$end_marker"
    } >> "$file"
    ok "Appended block to $file"
  else
    ok "Block already exists in $file. Skipping."
  fi
}

# Idempotently replaces a block, or creates it if it doesn't exist
replace_block() {
  local file="$1" begin="$2" end="$3" content="$4"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    print -P "%F{yellow}(dry-run)%f replace block [$begin ... $end] in $file"
    return 0
  fi
  [[ -f "$file" ]] || : > "$file"

  local python_bin="${PYTHON_BIN:-$(command -v python3 || true)}"
  if [[ -z "$python_bin" ]]; then
    err "python3 is required but was not found in PATH."
    return 1
  fi

  local tmp; tmp="$(mktemp)"
  TANY_BEGIN="$begin" TANY_END="$end" TANY_CONTENT="$content" "$python_bin" - "$file" "$tmp" <<'PY' || {
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
    print -P "%F{yellow}(dry-run)%f add plugin '$plugin' to $file"
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  awk -v plugin="$plugin" '
    /^[[:space:]]*plugins=\(/ {
      # Handle single-line plugins list safely by stripping trailing )
      line = $0
      line_end = line; sub(/\)\s*$/, "", line_end)
      # If already present, keep as is
      if (line_end ~ "(^|[[:space:]])" plugin "([[:space:]]|$)") { print; next }
      # Append before closing paren
      if (sub(/\)\s*$/, " " plugin ")", line)) { print line; next }
      in_plugins=1; seen=0
    }
    in_plugins {
      if ($0 ~ "(^|[[:space:]])" plugin "([[:space:]]|$)") { seen=1 }
    }
    in_plugins && /^[[:space:]]*\)/ {
      # Multiline plugins block: insert before closing paren if not present
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
    print -P "%F{yellow}(dry-run)%f dedup plugins in $file"
    return 0
  fi
  local tmp; tmp="$(mktemp)"
  awk '
    function flush(collected,   n,i,tok,seen,out) {
      # Output a normalized, single-line plugins block with unique entries
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
      # Capture any content after the opening paren on same line
      line=$0
      sub(/^[[:space:]]*plugins=\(/, "", line)
      if (line ~ /\)/) {
        sub(/\).*/, "", line); collected=collected " " line
        flush(collected); in_block=0; collected=""; next
      }
      # Defer printing; will output a single normalized line at flush
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
  local default_lower="${default:l}"
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    warn "(dry-run) auto-answering '${prompt}' with ${default_lower}"
    [[ "$default_lower" == "y" || "$default_lower" == "yes" ]]
    return
  fi

  # Auto-confirm/decline support via env vars; also handle non-interactive shells
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
    read "reply?${prompt} ${suffix} "
    reply="${reply:-$default_lower}"
    reply="${reply:l}"
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
      print -P "%F{yellow}(dry-run)%f would backup and remove $path"
      return 0
    fi
    # Use absolute paths to avoid PATH issues
    local bak_date
    bak_date=$(/bin/date +%Y%m%d-%H%M%S 2>/dev/null || date +%Y%m%d-%H%M%S)
    local bak="${path}.bak.${bak_date}"
    log "Backing up $path to $bak..."
    /bin/mv "$path" "$bak" 2>/dev/null || mv "$path" "$bak"
    ok "Backed up $path. Old version is at $bak."
  fi
}

# Writes content to a file atomically via a temp file
atomic_write() {
  local dest="$1" payload="$2" tmp
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    print -P "%F{yellow}(dry-run)%f write payload to $dest"
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
    # Execute the git command, capture exit status
    git "$@"; ret=$?
    # If successful, return 0
    (( ret == 0 )) && return 0
    # If not the last retry, warn and sleep
    (( i < 3 )) && { warn "Git command failed. Retrying ($i/3)..."; sleep 2; }
  done
  # If all retries failed, log error and return the last exit status
  err "Git command failed after 3 retries: $*"
  return $ret
}


# --- Dry Run ---
: "${DRY_RUN:=0}"

# run() takes args, run_s() takes a string to eval
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    print -P "%F{yellow}(dry-run)%f $*"
  else
    # Allow calling shell functions (e.g., git_retry) via run
    if typeset -f -- "$1" >/dev/null 2>&1; then
      "$@"
    else
      command "$@" # Prefer real executables for non-functions
    fi
  fi
}

run_s() {
  if [[ $DRY_RUN -eq 1 ]]; then
    print -P "%F{yellow}(dry-run)%f $1"
  else
    eval "$1" # Use eval sparingly for strings with pipes, subshells, etc.
  fi
}

run_git_config() {
  if [[ $DRY_RUN -eq 1 ]]; then
    print -P "%F{yellow}(dry-run)%f git config --global $1 \"$2\""
  else
    git config --global "$1" "$2"
  fi
}

# run_defaults accepts pass-through arguments
run_defaults() {
  if [[ $DRY_RUN -eq 1 ]]; then
    print -P "%F{yellow}(dry-run)%f defaults $*"
  else
    defaults "$@"
  fi
}
