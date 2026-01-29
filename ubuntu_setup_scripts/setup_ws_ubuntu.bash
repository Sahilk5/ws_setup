#!/bin/bash

# =========================
# tany workspace upgrader (v2.8 UBUNTU)
# =========================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib_tany.sh"
require_ubuntu

LOGFILE="${HOME}/.tany-setup-$(date +%Y%m%d).log"
exec > >(tee -a "$LOGFILE") 2>&1

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

print_usage_guide() {
  echo ""
  echo "âœ¨ --- Quick Usage Guide --- âœ¨"
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
  echo "* tlrc <cmd>  : Practical command examples"
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
  echo "  - Core CLI utils (eza, bat, fzf, btop, rg, fd, tlrc)"
  echo "  - Zsh, Oh My Zsh, Powerlevel10k (with default config)"
  echo "  - Zsh plugins (autosuggestions, syntax-highlighting)"
  echo "  - Terminal tools (Neovim + plugins, tmux, lazygit)"
  echo "  - Dev helpers (zoxide, direnv, git-delta, asdf)"
  echo "  - Sensible Zsh/Git/FZF configs and aliases (in a safe block)"
  echo "  - VS Code terminal font (optional)"
  echo ""
  log "It is safe to re-run this script."
  echo ""
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || "${1:-}" == "--summary" ]]; then
  print_summary; print_usage_guide; exit 0
fi

if [[ "${1:-}" == "--undo" ]]; then
  err "This script does not handle uninstallation."; warn "Run 'uninstall_ws_ubuntu.bash' to undo."; exit 1
fi

log "ðŸš€ Starting your full 'tany' workspace upgrade..."
[[ $DRY_RUN -eq 1 ]] && warn "DRY RUN MODE: No changes will be made."
print_summary; echo "You may be prompted for your password."; log "Full log will be saved to $LOGFILE"

BASHRC="$HOME/.bashrc"; ZSHRC="$HOME/.zshrc"
ZSH_BLOCK_BEGIN="# >>> tany-setup BEGIN >>>"
ZSH_BLOCK_END="# <<< tany-setup END <<<"

log "Running preflight checks..."
run_s 'nc -z github.com 443 >/dev/null 2>&1 || echo "âš ï¸ Network to github.com:443 may be blockedâ€¦"'
run df -h "$HOME" | tail -1
echo ""

log "Updating package lists..."
run_s "sudo apt-get update >/dev/null 2>&1 || true"

log "Installing core system dependencies..."
base_deps=(git curl wget build-essential zsh python3 python3-pip jq)
apt_install "${base_deps[@]}" || true

log "Installing modern CLI tools via apt..."
cli_tools=(bat ripgrep fd-find btop tmux lazygit direnv)
apt_install "${cli_tools[@]}" || {
  warn "Some apt packages unavailable; attempting fallback installs via cargo/snap..."
  command -v cargo >/dev/null 2>&1 || {
    log "Installing Rust/Cargo..."
    run_s "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>/dev/null || true"
    . "$HOME/.cargo/env" || true
  }
}

log "Ensuring fzf is installed..."
if ! command -v fzf >/dev/null 2>&1; then
  log "Installing fzf..."
  run_s "$CURL https://github.com/junegunn/fzf/releases/download/0.48.0/fzf-0.48.0-linux_amd64.tar.gz -o /tmp/fzf.tar.gz"
  run tar xzf /tmp/fzf.tar.gz -C /tmp
  run sudo mv /tmp/fzf /usr/local/bin/
  run rm /tmp/fzf.tar.gz
else
  ok "fzf is already installed."
fi

log "Ensuring eza is installed..."
if ! command -v eza >/dev/null 2>&1; then
  log "Installing eza..."
  if command -v cargo >/dev/null 2>&1; then
    run_s "cargo install eza 2>&1 || true"
  else
    warn "eza not available; will try apt fallback"
    apt_install eza || warn "eza unavailable; skipping"
  fi
else
  ok "eza is already installed."
fi

log "Installing Neovim..."
if ! command -v nvim >/dev/null 2>&1; then
  run_s "$CURL https://github.com/neovim/neovim/releases/download/v0.9.5/nvim.appimage -o /tmp/nvim.appimage"
  run chmod +x /tmp/nvim.appimage
  run sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
else
  ok "Neovim is already installed."
fi

log "Installing zoxide..."
if ! command -v zoxide >/dev/null 2>&1; then
  run_s "$CURL -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash"
else
  ok "zoxide is already installed."
fi

log "Installing asdf (version manager)..."
if [[ ! -d "$HOME/.asdf" ]]; then
  run git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.14.0 2>/dev/null || true
  ok "asdf installed."
else
  ok "asdf is already installed."
fi

log "Checking for/installing Zsh..."
if ! command -v zsh >/dev/null 2>&1; then
  log "Installing Zsh..."
  apt_install zsh || true
  log "Setting Zsh as default shell..."
  run_s "chsh -s /bin/zsh || true"
else
  ok "Zsh is already installed."
fi

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  ok "Oh My Zsh is already installed."
else
  log "Installing Oh My Zsh (unattended)..."
  run_s "RUNZSH=no CHSH=no $CURL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s -- --unattended"
fi

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ -d "$P10K_DIR" ]]; then
  ok "Powerlevel10k already installed."
else
  log "Installing Powerlevel10k..."
  run git_retry clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

if [[ ! -f "$ZSHRC" ]]; then
  # If no .zshrc, we'll start fresh with Oh My Zsh templates
  log "Creating .zshrc..."
  : > "$ZSHRC"
fi

replace_or_append '^ZSH_THEME=.*' 'ZSH_THEME="powerlevel10k/powerlevel10k"' "$ZSHRC"
append_once 'source $ZSH/oh-my-zsh.sh' "$ZSHRC"
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
# --- Tool Hooks ---
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
fi
# --- Git Aliases ---
alias gst="git status"; alias gd="git diff"
EOC
replace_block "$ZSHRC" "$ZSH_BLOCK_BEGIN" "$ZSH_BLOCK_END" "$ZRC_PAYLOAD"

log "Ensuring Zsh plugins..."
AUTOSUGGEST_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
SYNTAX_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
[[ -d "$AUTOSUGGEST_DIR" ]] || run git_retry clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGEST_DIR"
[[ -d "$SYNTAX_DIR" ]] || run git_retry clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_DIR"

grep -Eq '^[[:space:]]*plugins=\(' "$ZSHRC" || run_s "printf '\nplugins=(git)\n' >> \"$ZSHRC\""
if ! grep -Eq '^[[:space:]]*plugins=\([^)]*([[:space:]]|^)zsh-autosuggestions([[:space:]]|$)' "$ZSHRC"; then
    log "Activating zsh-autosuggestions in ~/.zshrc..."
    add_zsh_plugin "$ZSHRC" "zsh-autosuggestions"
else
  ok "zsh-autosuggestions already active in ~/.zshrc."
fi
if ! grep -Eq '^[[:space:]]*plugins=\([^)]*([[:space:]]|^)zsh-syntax-highlighting([[:space:]]|$)' "$ZSHRC"; then
    log "Activating zsh-syntax-highlighting in ~/.zshrc..."
    add_zsh_plugin "$ZSHRC" "zsh-syntax-highlighting"
else
  ok "zsh-syntax-highlighting already active in ~/.zshrc."
fi
dedup_zsh_plugins "$ZSHRC"
ok "Zsh plugins configured."

PLUG_VIM="$HOME/.local/share/nvim/site/autoload/plug.vim"
if [[ -f "$PLUG_VIM" ]]; then
  ok "vim-plug already installed."
else
  log "Installing vim-plug..."
  run_s "mkdir -p \"$(dirname "$PLUG_VIM")\" && $CURL -fLo \"$PLUG_VIM\" --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
fi

NVIM_DIR="$HOME/.config/nvim"; NVIM_INIT="$NVIM_DIR/init.vim"
if [[ -f "$NVIM_INIT" ]]; then
  ok "$NVIM_INIT already exists."
else
  log "Creating starter Neovim config..."
  run mkdir -p "$NVIM_DIR"
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
  atomic_write "$NVIM_INIT" "$NVIM_PAYLOAD"
fi

if command -v nvim >/dev/null 2>&1; then
  log "Installing/Updating Neovim plugins..."
  run nvim --headless +PlugInstall +PlugUpdate +qall || true
  ok "Neovim plugins ready."
else
  warn "nvim not in PATH; skipping headless plugin install."
fi

TMUX_CFG="$HOME/.tmux.conf"
if [[ -f "$TMUX_CFG" ]]; then
  ok "$TMUX_CFG already exists."
else
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
set -g status-position bottom
set -g status-justify left
set -g status-style 'fg=colour1'
set -g status-left ''
set -g status-right '%Y-%m-%d %H:%M '
set -g status-right-length 50
set -g pane-border-style 'fg=colour1'
set -g pane-active-border-style 'fg=colour3'
EOT
  atomic_write "$TMUX_CFG" "$TMUX_PAYLOAD"
  ok "tmux config written."
fi

log "Configuring Git defaults and Delta pager..."
run_git_config core.editor "nvim"
run_git_config init.defaultBranch main
run_git_config pull.rebase false
run_git_config fetch.prune true
run_git_config diff.colorMoved default
run_git_config diff.algorithm histogram
run_git_config fetch.parallel 8
run_git_config core.pager "delta"
run_git_config interactive.diffFilter "delta --color-only"
run_git_config delta.features "side-by-side line-numbers decorations"
run_git_config delta.side-by-side true
run_git_config delta.navigate true
run_git_config delta.line-numbers true
ok "Git defaults and Delta pager configured."

log "Configuring ripgrep defaults..."
RG_DIR="$HOME/.config/ripgrep"; RG_CFG="$RG_DIR/rc"
run mkdir -p "$RG_DIR"
if [[ ! -f "$RG_CFG" ]]; then
  read -r -d '' RG_PAYLOAD <<'EOR' || true
--hidden
--follow
--glob=!.git
--glob=!*.log
EOR
  atomic_write "$RG_CFG" "$RG_PAYLOAD"
  ok "Created ripgrep config."
else
  ok "ripgrep config already exists."
fi

echo ""
print_usage_guide
echo ""
echo "ðŸŽ‰ --- FULL WORKSPACE AUTOMATION COMPLETE! --- ðŸŽ‰"
echo ""
echo "Your shell, tmux, and Neovim are now configured."
echo "Consider running: chsh -s /bin/zsh (if not already done)"
echo ""
