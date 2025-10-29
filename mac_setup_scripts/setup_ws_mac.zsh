#!/bin/zsh

# =========================
# tany workspace upgrader (v2.5 FINAL)
# =========================

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/lib_tany.sh"
require_macos

LOGFILE="${HOME}/.tany-setup-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

print_usage_guide() {
  echo ""
  echo "✨ --- Quick Usage Guide --- ✨"
  echo "* bat <file>  : Pretty 'cat'"
  echo "* eza         : Pretty 'ls' (try new aliases below)"
  echo "* l           : 'eza -l --git --icons' (Detailed list)"
  echo "* la          : 'eza -la --git --icons' (Detailed list, all files)"
  echo "* lt          : 'eza --tree --level=2' (Directory tree)"
  echo "* fzf         : Fuzzy finder (Ctrl-R for history, preview enabled)"
  echo "* btop        : System monitor"
  echo "* vim <file>  : Neovim (aliased to 'vim')"
  echo "* rg <pat>    : ripgrep (fast grep)"
  echo "* fd <pat>    : find by name"
  echo "* gl          : lazygit UI (alias for 'lazygit')"
  echo "* tldr <cmd>  : Practical command examples"
  echo "* z <dir>     : 'zoxide' (jump to frequent dirs)"
  echo "* direnv      : Per-project .envrc loader (now hooked)"
  echo "* git diff    : Now uses 'git-delta' (side-by-side view)"
  echo "* tmux        : Multiplexer (launch with 'tmux')"
  echo "* asdf        : Language version manager (now hooked)"
  echo ""
  echo "NOTE: Aliases (l, la, lt, gl, vim) are on by default."
  echo "To temporarily disable them for testing, run:"
  echo "  export TANY_DISABLE_ALIASES=1"
  echo ""
}

print_summary() {
  echo ""
  log "This script will idempotently install and configure:"
  echo "  - Xcode CLT (check), Homebrew & core CLI utils (eza, bat, fzf, btop, rg, fd, tldr)"
  echo "  - Zsh, Oh My Zsh, Powerlevel10k (with default config)"
  echo "  - Zsh plugins (autosuggestions, syntax-highlighting)"
  echo "  - Terminal tools (Neovim + plugins, tmux, lazygit)"
  echo "  - Dev helpers (zoxide, direnv, git-delta, asdf stub, Rosetta)"
  echo "  - Sensible Zsh/Git/FZF configs and aliases (in a safe block)"
  echo "  - iTerm2 'tany' profile & VS Code terminal font (optional)"
  echo ""
  log "It is safe to re-run this script."
  echo ""
}
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; print_usage_guide; exit 0
fi
if [[ "${1:-}" == "--undo" ]]; then
  err "This script does not handle uninstallation."; warn "Run 'uninstall_ws_mac.zsh' to undo."; exit 1
fi
log "🚀 Starting your full 'tany' workspace upgrade..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary; echo "You may be prompted for your password."; log "Full log will be saved to $LOGFILE"
ZSHRC="$HOME/.zshrc"; ZPROFILE="$HOME/.zprofile"
ZSH_BLOCK_BEGIN="# >>> tany-setup BEGIN >>>"; ZSH_BLOCK_END="# <<< tany-setup END <<<"
ZPROFILE_BLOCK_BEGIN="# >>> tany-setup-zprofile BEGIN >>>"; ZPROFILE_BLOCK_END="# <<< tany-setup-zprofile END <<<"
log "Running preflight checks..."
run_s 'nc -z github.com 443 >/dev/null 2>&1 || echo "⚠️ Network to github.com:443 may be blocked…"'
run df -h "$HOME" | tail -1; echo ""
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."; run_s "/bin/bash -c \"$($CURL -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
else
  ok "Homebrew is already installed."; log "Updating Homebrew..."; run brew update
fi
log "Checking for Xcode Command Line Tools..."
if ! xcode-select -p >/dev/null 2>&1; then
  warn "Xcode Command Line Tools not found. Attempting install..."
  run_s "xcode-select --install || true"; log "Waiting up to 2 minutes for Xcode CLT install to finish..."
  for _ in {1..60}; do xcode-select -p >/dev/null 2>&1 && break; sleep 2; done
  if xcode-select -p >/dev/null 2>&1; then ok "Xcode CLT installed successfully."; else warn "Xcode CLT install timed out or failed."; fi
else
  ok "Xcode Command Line Tools already installed."
fi
log "Ensuring Homebrew is in PATH..."
if [[ -d "/opt/homebrew" ]]; then
  BREW_PATH_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'; run_s "eval \"$BREW_PATH_LINE\""
else
  BREW_PATH_LINE='eval "$(/usr/local/bin/brew shellenv)"'; run_s "eval \"$BREW_PATH_LINE\""
fi
replace_block "$ZPROFILE" "$ZPROFILE_BLOCK_BEGIN" "$ZPROFILE_BLOCK_END" "$BREW_PATH_LINE"
if [[ "$(uname -m)" == "arm64" ]]; then
  log "Ensuring Rosetta 2 is installed..."
  run_s "sudo -n /usr/sbin/softwareupdate --install-rosetta --agree-to-license || /usr/sbin/softwareupdate --install-rosetta --agree-to-license || true"
  ok "Rosetta 2 check complete."
fi
log "Ensuring packages are installed..."
run brew tap homebrew/cask-fonts >/dev/null 2>&1 || true
casks=(iterm2 font-hack-nerd-font)
formulas=(bat eza fzf btop neovim ripgrep fd lazygit jq tmux tldr zoxide direnv git-delta asdf)
run brew install "${formulas[@]}" || true; run brew install --cask "${casks[@]}" || true
ok "Homebrew apps and tools ensured."
if [[ -d "$HOME/.oh-my-zsh" ]]; then ok "Oh My Zsh is already installed."; else
  log "Installing Oh My Zsh (unattended)..."
  run_s "$CURL -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | RUNZSH=no CHSH=no sh -s -- --unattended"
fi
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ -d "$P10K_DIR" ]]; then ok "Powerlevel10k already installed."; else
  log "Installing Powerlevel10k..."; run git_retry clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi
replace_or_append '^ZSH_THEME=.*' 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$ZSHRC"
append_once '[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh' "$ZSHRC"
log "Applying Zsh quality-of-life settings..."
read -r -d '' ZRC_PAYLOAD <<'EOC' || true
# --- Zsh History Settings ---
HISTSIZE=500000
SAVEHIST=500000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_DUPS HIST_REDUCE_BLANKS HIST_FIND_NO_DUPS
setopt SHARE_HISTORY EXTENDED_HISTORY
# --- FZF (Fuzzy Finder) Settings ---
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob !{.git,node_modules} || fd -H -t f'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS='--height 60% --reverse --border --inline-info --preview "bat --color=always --style=plain --line-range=:50 {}"'
# --- General Aliases ---
if [[ -z "${TANY_DISABLE_ALIASES:-}" ]]; then
  alias vim="nvim"; alias gl="lazygit"
  alias l="eza -l --git --icons"; alias la="eza -la --git --icons"; alias lt="eza --tree --level=2"
  alias ..="cd .."; alias ...="cd ../.."; alias ....="cd ../../../"
  alias please="sudo !!"; alias grep="grep --color=auto"
fi
# --- make Flags ---
if [[ -z "${TANY_DISABLE_MAKEJ:-}" ]]; then
  export MAKEFLAGS="-j$(sysctl -n hw.ncpu)"
fi
# --- Tool Hooks ---
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
if [ -f "$(brew --prefix asdf)/libexec/asdf.sh" ]; then
  . "$(brew --prefix asdf)/libexec/asdf.sh"
fi
# --- Homebrew Settings ---
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
EOC
replace_block "$ZSHRC" "$ZSH_BLOCK_BEGIN" "$ZSH_BLOCK_END" "$ZRC_PAYLOAD"
FZF_KEYS_BREW="$(brew --prefix 2>/dev/null)/opt/fzf/shell/key-bindings.zsh"
if [[ -f "$FZF_KEYS_BREW" ]] && ! grep -q "key-bindings.zsh" "$ZSHRC"; then
  append_once "source \"$FZF_KEYS_BREW\"" "$ZSHRC"; ok "fzf keybindings sourced from brew."
elif [[ -f "$HOME/.fzf.zsh" ]] && ! grep -q ".fzf.zsh" "$ZSHRC"; then
   append_once "source \"$HOME/.fzf.zsh\"" "$ZSHRC"; ok "fzf keybindings sourced from home."
elif grep -q "fzf" "$ZSHRC"; then ok "fzf keybindings already configured."; else
  log "Installing fzf keybindings..."; run_s "\"$(brew --prefix)\"/opt/fzf/install --all || true"
fi
log "Ensuring Zsh plugins..."
ZSHRC_FILE="$ZSHRC"; ZSHRC_TEMP=$(mktemp)
AUTOSUGGEST_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
SYNTAX_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
[[ -d "$AUTOSUGGEST_DIR" ]] || run git_retry clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGEST_DIR"
[[ -d "$SYNTAX_DIR"    ]] || run git_retry clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_DIR"
grep -Eq '^[[:space:]]*plugins=\(' "$ZSHRC_FILE" || run_s "printf '\nplugins=(git)\n' >> \"$ZSHRC_FILE\""
if ! grep -Eq '^[[:space:]]*plugins=\([^)]*([[:space:]]|^)zsh-autosuggestions([[:space:]]|$)' "$ZSHRC_FILE"; then
    log "Activating zsh-autosuggestions in ~/.zshrc..."
    add_zsh_plugin "$ZSHRC_FILE" "zsh-autosuggestions"
else ok "zsh-autosuggestions already active in ~/.zshrc."; fi
if ! grep -Eq '^[[:space:]]*plugins=\([^)]*([[:space:]]|^)zsh-syntax-highlighting([[:space:]]|$)' "$ZSHRC_FILE"; then
    log "Activating zsh-syntax-highlighting in ~/.zshrc..."
    add_zsh_plugin "$ZSHRC_FILE" "zsh-syntax-highlighting"
else ok "zsh-syntax-highlighting already active in ~/.zshrc."; fi
rm -f "$ZSHRC_TEMP"; ok "Zsh plugins configured."
P10K_CFG="$HOME/.p10k.zsh"
if [[ -f "$P10K_CFG" ]]; then ok "Found existing .p10k.zsh"; else
  log "Creating default .p10k.zsh (no wizard)..."
  read -r -d '' P10K_PAYLOAD <<'EOP' || true
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=( os_icon dir vcs )
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=( status command_execution_time time )
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always
typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=true
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_from_right
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
EOP
  atomic_write "$P10K_CFG" "$P10K_PAYLOAD"; fi
log "Ensuring iTerm2 Dynamic Profile..."
ITERM_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"; ITERM_FILE="$ITERM_DIR/tany.json"
run mkdir -p "$ITERM_DIR"
if [[ ! -f "$ITERM_FILE" ]]; then
  GUID="tany-$(uuid)"
  read -r -d '' ITERM_PAYLOAD <<EOF || true
{ "Profiles": [ { "Name": "tany", "Guid": "$GUID", "Normal Font": "HackNerdFont-Regular 14", "Non-ASCII Font": "HackNerdFont-Regular 14", "Use Non-ASCII Font": true, "Unlimited Scrollback": true, "Natural Text Editing": true, "Silence Bell": true } ] }
EOF
  atomic_write "$ITERM_FILE" "$ITERM_PAYLOAD"; ok "Created iTerm2 'tany' dynamic profile."
else ok "iTerm2 'tany' dynamic profile already exists."; fi
PLUG_VIM="$HOME/.local/share/nvim/site/autoload/plug.vim"
if [[ -f "$PLUG_VIM" ]]; then ok "vim-plug already installed."; else
  log "Installing vim-plug..."; run_s "$CURL -fLo \"$PLUG_VIM\" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
fi
NVIM_DIR="$HOME/.config/nvim"; NVIM_INIT="$NVIM_DIR/init.vim"
if [[ -f "$NVIM_INIT" ]]; then ok "$NVIM_INIT already exists."; else
  log "Creating starter Neovim config..."; run mkdir -p "$NVIM_DIR"
  read -r -d '' NVIM_PAYLOAD <<'EOV' || true
call plug#begin('~/.local/share/nvim/plugged')
Plug 'dracula/vim'
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/tagbar'
Plug 'sheerun/vim-polyglot'
call plug#end()
syntax on
set number relativenumber cursorline termguicolors background=dark
colorscheme dracula
let mapleader = " "
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>t :TagbarToggle<CR>
EOV
  atomic_write "$NVIM_INIT" "$NVIM_PAYLOAD"; fi
if command -v nvim >/dev/null 2>&1; then
  log "Installing/Updating Neovim plugins..."; run nvim --headless +PlugInstall +PlugUpdate +qall || true; ok "Neovim plugins ready."
else warn "nvim not in PATH; skipping headless plugin install."; fi
TMUX_CFG="$HOME/.tmux.conf"
if [[ -f "$TMUX_CFG" ]]; then ok "$TMUX_CFG already exists."; else
  log "Creating ~/.tmux.conf..."
  read -r -d '' TMUX_PAYLOAD <<'EOT' || true
set -g mouse on
set -g default-shell /bin/zsh
set -g default-terminal "tmux-256color"
set -as terminal-overrides ',xterm-256color:Tc'
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
set -g visual-activity off
set -g visual-bell off
set -g visual-silence off
setw -g monitor-activity off
set -g bell-action none
setw -g clock-mode-colour colour1
setw -g mode-style 'fg=colour1 bg=colour18 bold'
set -g pane-border-style 'fg=colour1'
set -g pane-active-border-style 'fg=colour3'
set -g status-position bottom
set -g status-justify left
set -g status-style 'fg=colour1'
set -g status-left ''
set -g status-right '%Y-%m-%d %H:%M '
set -g status-right-length 50
set -g status-left-length 10
setw -g window-status-current-style 'fg=colour0 bg=colour1 bold'
setw -g window-status-current-format ' #I #W #F '
setw -g window-status-style 'fg=colour1 dim'
setw -g window-status-format ' #I #[fg=colour7]#W #[fg=colour1]#F '
setw -g window-status-bell-style 'fg=colour2 bg=colour1 bold'
set -g message-style 'fg=colour2 bg=colour0 bold'
EOT
  atomic_write "$TMUX_CFG" "$TMUX_PAYLOAD"; ok "tmux config written."; fi
if command -v tic >/dev/null; then
  log "Ensuring tmux terminfo is available..."
  read -r -d '' TMUX_TERMINFO <<'EOI' || true
tmux-256color|tmux with 256 colors,
  use=xterm-256color,
EOI
  run_s "echo \"$TMUX_TERMINFO\" | tic -x - 2>/dev/null || true"; fi
log "Configuring Git defaults and Delta pager..."
run_git_config core.editor "nvim"; run_git_config init.defaultBranch main
run_git_config pull.rebase false; run_git_config fetch.prune true
run_git_config diff.colorMoved default; run_git_config diff.algorithm histogram
run_git_config fetch.parallel 8; run_git_config core.pager "delta"
run_git_config interactive.diffFilter "delta --color-only"
run_git_config delta.features "side-by-side line-numbers decorations"
run_git_config delta.side-by-side true; run_git_config delta.navigate true
run_git_config delta.line-numbers true; ok "Git defaults and Delta pager configured."
log "Configuring ripgrep defaults..."
RG_DIR="$HOME/.config/ripgrep"; RG_CFG="$RG_DIR/rc"; run mkdir -p "$RG_DIR"
if [[ ! -f "$RG_CFG" ]]; then
  read -r -d '' RG_PAYLOAD <<'EOR' || true
--hidden
--follow
--glob=!.git
--glob=!*.log
EOR
  atomic_write "$RG_CFG" "$RG_PAYLOAD"; ok "Created ripgrep config."
else ok "ripgrep config already exists."; fi
log "Updating tldr cache..."; run tldr --update || true
echo ""
if [[ $DRY_RUN -eq 1 ]]; then warn "Skipping VS Code prompt in --dry-run mode."
elif ! command -v jq >/dev/null; then
  warn "jq not found. Skipping VS Code configuration."; warn "Run 'brew install jq' and re-run this script."
else
  if confirm_prompt "Do you want to automatically configure the VS Code integrated terminal? (y/n)" "no"; then
    VSC_DIR="$HOME/Library/Application Support/Code/User"; VSC_SETTINGS="$VSC_DIR/settings.json"
    if [[ -d "$VSC_DIR" ]]; then
      log "Configuring VS Code terminal..."
      [[ -f "$VSC_SETTINGS" && -s "$VSC_SETTINGS" ]] || echo "{}" > "$VSC_SETTINGS"
      cp -p "$VSC_SETTINGS" "$VSC_SETTINGS.bak" 2>/dev/null || true
      TEMP_JSON="$(mktemp)"
      if jq '.["terminal.integrated.fontFamily"]="HackNerdFont-Regular"
            | .["terminal.integrated.defaultProfile.osx"]="zsh"
            | .["terminal.integrated.defaultProfile"]="zsh"' \
            "$VSC_SETTINGS" > "$TEMP_JSON"; then
        run mv "$TEMP_JSON" "$VSC_SETTINGS"; ok "VS Code terminal font and profile set."
      else
        err "Could not parse $VSC_SETTINGS; leaving backup at $VSC_SETTINGS.bak"; rm -f "$TEMP_JSON"
      fi
    else ok "VS Code user settings directory not found; skipping."; fi
  else log "Skipping VS Code configuration."; fi
fi
log "Running Homebrew health check and cleanup..."
run brew doctor >/dev/null || true
run brew cleanup -s || true
print_usage_guide
echo ""; echo "🎉 --- FULL WORKSPACE AUTOMATION COMPLETE! --- 🎉"
echo ""; echo "Your iTerm, Zsh, tmux, and Neovim are now upgraded."; echo ""
echo "One manual step for iTerm2:"
echo "  1) Quit and relaunch iTerm2"
echo "  2) Settings (Cmd + ,) → Profiles"
echo "  3) Select 'tany' → Other Actions… → Set as Default"
echo ""; echo "All new iTerm2 windows will now use the correct font, theme, and plugins!"
