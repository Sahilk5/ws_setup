# Tany Workspace Setup 🚀

This repository contains scripts and tools to set up a developer workspace. If you're here to automate a macOS workstation, jump straight to the platform-specific guide:

- macOS setup: mac_setup_scripts/README.md

**Automate your macOS development environment setup with this safe, idempotent, and modular toolkit.**

This collection of scripts installs and configures a modern, productive command-line environment on macOS. It focuses on enhancing the core developer experience with powerful tools, sensible defaults, and quality-of-life improvements, while remaining robust and easy to manage.

## Philosophy

- **Modern Tools:** Leverages faster, more user-friendly CLI tools (like `eza`, `bat`, `rg`, `fzf`, `neovim`).
- **Consistency:** Aims for a consistent feel across iTerm2, tmux, and VS Code's integrated terminal.
- **Safety First:** Designed to be idempotent (safe to re-run) and uses error trapping, backups, and atomic writes where possible.
- **Modularity:** Separates concerns into distinct scripts (base, apps, system defaults, languages, security) managed by a central wrapper.
- **Minimal Base:** Keeps the core setup lean, allowing optional additions for GUI apps, specific language runtimes, or invasive system tweaks.

## ✨ Features by Module

### Core (`./tany install base`)

- **Homebrew:** Installs or updates the essential macOS package manager.
- **Xcode Command Line Tools:** Checks for and prompts installation if missing.
- **Rosetta 2 (Apple Silicon):** Ensures the compatibility layer for Intel binaries is available.
- **Modern Core Utilities:** Installs `eza`, `bat`, `fzf`, `btop`, `ripgrep`, `fd`, `tldr`, and wires in ergonomic aliases.
- **Zsh Environment:** Installs Oh My Zsh, Powerlevel10k, Autosuggestions, Syntax Highlighting, improved history, and quality-of-life aliases.
- **Terminal Tools:** Configures Neovim (with starter config and plugins), tmux (with power user defaults), and lazygit.
- **Developer Helpers:** Enables zoxide, direnv, git-delta, and asdf.
- **Sensible Defaults:** Applies Git configuration tweaks, FZF defaults, and disables Homebrew analytics.
- **iTerm2 Profile:** Creates a dynamic profile named `tany` using Hack Nerd Font for Powerlevel10k.
- **VS Code Prompt:** Optionally syncs the integrated terminal font/profile to match the shell.

### Optional Modules

- **GUI Apps (`./tany install apps`):** Uses the `Brewfile` to install GUI applications and cloud CLIs. Customize by editing the file.
- **macOS Defaults (`./tany install defaults`):** Applies opinionated system tweaks (keyboard, Finder, Dock, UI). Review before running. Revert with `./tany uninstall defaults`.
- **Language Runtimes (`./tany install languages`):** Installs Node.js, Python, Java, and Go via `asdf`. Customize versions in `dev-languages.zsh`.
- **VS Code Extensions (`./tany install vscode`):** Installs a curated list of VS Code extensions. Customize in `vscode-extensions.zsh`. Uninstall with `./tany uninstall vscode`.
- **Security (`./tany security`):** Interactive helper for Git identity, SSH key creation, and GitHub CLI auth.

## 🏗️ Repository Layout

```
mac_setup_scripts/
  tany                   # Wrapper entry point
  lib_tany.sh            # Shared helpers (logging, dry-run, atomics, etc.)
  setup_ws_mac.zsh       # Core installer
  uninstall_ws_mac.zsh   # Core uninstaller
  Brewfile               # GUI app bundle
  apps.zsh               # Install GUI apps
  uninstall-apps.zsh     # Remove GUI apps
  macos-defaults.zsh     # Apply system tweaks
  undo-macos-defaults.zsh# Revert system tweaks
  dev-languages.zsh      # Install runtimes via asdf
  security.zsh           # Interactive security helper
  vscode-extensions.zsh  # Manage VS Code extensions
```

All scripts log to timestamped files in your home directory (for example, `~/.tany-setup-YYYYMMDD.log`).

## ✅ Prerequisites

- macOS Monterey or newer (tested on recent releases).
- Internet connection for downloads.
- Xcode Command Line Tools (checked and prompted for during the base install).

## 🚀 Usage

Clone the repository and run the wrapper:

```bash
git clone https://github.com/Sahilk5/ws_setup.git tany-workspace
cd tany-workspace/mac_setup_scripts
./tany help
```

Typical workflow:

```bash
./tany install base          # Core environment
./tany security              # Interactive identity setup
./tany install apps          # Optional GUI additions
./tany install languages     # Install language runtimes
./tany install defaults      # Apply system defaults (review first!)
./tany install vscode        # Sync VS Code extensions
```

**Dry Run:** Append `--dry-run` to preview actions, e.g. `./tany install base --dry-run`.

**All-in-One:** `./tany install all`

## 📌 Manual iTerm2 Step (Important)

After `./tany install base`, configure iTerm2 to use the `tany` profile:

1. Quit and relaunch iTerm2.
2. Open Preferences (`Cmd + ,`).
3. Go to the Profiles tab.
4. Select `tany` in the list.
5. Click `Other Actions…` → `Set as Default`.
6. Open a new window/tab to enjoy the configured prompt.

## 🔁 Idempotency & Safety

- Scripts use strict shell options and a trap to exit immediately on errors.
- Config files are written atomically and backed up before being replaced.
- `.zshrc` and `.zprofile` modifications live inside clearly marked BEGIN/END blocks for easy updates and removals.
- Network operations are retried and most commands support dry-run mode.

## 🛠️ Customization Tips

- **GUI Apps:** Edit `mac_setup_scripts/Brewfile`.
- **VS Code Extensions:** Edit the `EXTENSIONS` array in `mac_setup_scripts/vscode-extensions.zsh`.
- **Language Versions:** Tweak version variables in `mac_setup_scripts/dev-languages.zsh`.
- **Aliases & Shell Config:** Modify the heredoc block in `mac_setup_scripts/setup_ws_mac.zsh` and re-run the base installer.
- **Prompt:** Run `p10k configure` at any time to customize Powerlevel10k.

## ⏪ Uninstallation

Use the wrapper to remove components:

```bash
./tany uninstall base
./tany uninstall apps
./tany uninstall defaults
./tany uninstall vscode
./tany uninstall all
```

`languages` and `security` modules do not have uninstallers; remove runtimes manually if needed.

## 🤝 Contributing

- Fork the repo and submit pull requests for enhancements or bug fixes.
- Open an issue if you find a problem or have suggestions for improvements.
- All scripts are written in Zsh; please keep new contributions POSIX-ish where possible.

## 📄 License

MIT © Sahil Kaushal
