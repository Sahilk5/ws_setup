# Tany Workspace Setup (macOS) 🚀

**Automate your macOS development environment setup with this safe, idempotent, and modular toolkit.**

For project‑wide context, see the repository README (../README.md).

This collection of scripts installs and configures a modern, productive command-line environment on macOS. It focuses on enhancing the core developer experience with powerful tools, sensible defaults, and quality-of-life improvements, while remaining robust and easy to manage.

**Philosophy:**
* **Modern Tools:** Leverages faster, more user-friendly CLI tools (like `eza`, `bat`, `rg`, `fzf`, `neovim`).
* **Consistency:** Aims for a consistent feel across iTerm2, tmux, and VS Code's integrated terminal.
* **Safety First:** Designed to be idempotent (safe to re-run) and uses error trapping, backups, and atomic writes where possible.
* **Modularity:** Separates concerns into distinct scripts (base, apps, system defaults, languages, security) managed by a central wrapper.
* **Minimal Base:** Keeps the core setup lean, allowing optional additions for GUI apps, specific language runtimes, or invasive system tweaks.

---

## ✨ Features

The toolkit provides a layered setup:

### Core (`./tany install base`)
* **Homebrew:** Installs or updates the essential macOS package manager.
* **Xcode Command Line Tools:** Checks for and prompts installation if missing (required by Homebrew for building some packages).
* **Rosetta 2 (Apple Silicon):** Ensures compatibility layer for Intel-based tools is installed.
* **Modern Core Utilities:**
    * `eza`: A modern `ls` replacement with icons, Git awareness, and better defaults. Includes `l`, `la`, `lt` aliases.
    * `bat`: A `cat` clone with syntax highlighting and Git integration.
    * `fzf`: A command-line fuzzy finder, integrated with shell history (`Ctrl+R`) and file finding (`Ctrl+T`), with file previews using `bat`.
    * `btop`: An interactive system monitor, superior to `top` and `htop`.
    * `ripgrep` (`rg`): Extremely fast recursive code search tool (better `grep`).
    * `fd`: Simple and fast alternative to `find`.
    * `tldr`: Community-driven, practical examples for command-line tools.
* **Zsh Environment:**
    * Installs **Oh My Zsh** framework.
    * Installs and configures **Powerlevel10k** for a fast, customizable prompt (skips initial wizard, uses a functional default; run `p10k configure` to customize).
    * Enables **`zsh-autosuggestions`** (suggests commands from history) and **`zsh-syntax-highlighting`** (colors commands as you type).
    * Configures Zsh history for better retention and de-duplication.
* **Terminal Tools:**
    * **Neovim (`nvim`):** Installs the modern Vim fork. Sets up `vim-plug` plugin manager and a starter `init.vim` config (`~/.config/nvim/init.vim`) with Dracula theme, NERDTree (file explorer), Airline (status bar), Tagbar, and Polyglot (syntax highlighting). Automatically installs plugins. Aliases `vim` to `nvim`.
    * **tmux:** Installs the terminal multiplexer. Creates a user-friendly `~/.tmux.conf` enabling mouse support, 256 colors, Zsh as default shell, easier pane splitting/navigation, and Vim-style keys. Installs `tmux-256color` terminfo.
    * **lazygit:** Installs a terminal UI for Git. Adds `gl` alias.
* **Developer Helpers:**
    * **`zoxide` (`z`):** A smarter `cd` command that learns your frequently used directories.
    * **`direnv`:** Loads and unloads environment variables depending on the current directory (uses `.envrc` files).
    * **`git-delta`:** Provides enhanced, side-by-side diff views for `git diff`, `git log`, `git show`, etc. Configured as the default Git pager.
    * **`asdf`:** Installs the language version manager and hooks it into Zsh (use `dev-languages.zsh` to install specific runtimes).
* **Sensible Defaults:**
    * Configures Git for common scenarios (default branch `main`, editor `nvim`, prune on fetch, better diff algorithm).
    * Adds useful Zsh aliases (`l`, `la`, `lt`, `..`, `...`, `....`, `please`, `grep`, `make` with parallel jobs). See `~/.zshrc` (`tany-setup` block).
    * Sets FZF options for better preview and layout.
    * Sets Homebrew environment variables to disable analytics and hints.
* **iTerm2 Profile:** Creates an iTerm2 dynamic profile named "tany" pre-configured with `HackNerdFont-Regular 14pt` (required for Powerlevel10k icons).
* **VS Code Terminal (Optional):** Prompts to configure the integrated terminal to use Zsh and the Nerd Font for consistency.

### Optional Modules
* **GUI Apps (`./tany install apps`):** Installs common GUI apps (Docker, Postman, browsers, etc.) and cloud CLIs (`gh`, `awscli`) via a `Brewfile`. Easily customizable by editing `Brewfile`.
* **macOS Defaults (`./tany install defaults`):** Applies opinionated macOS system settings for Finder, Dock, Keyboard, etc. **Warning:** This is invasive and changes system behavior. Review `macos-defaults.zsh` before running. Has an uninstaller (`./tany uninstall defaults`).
* **Language Runtimes (`./tany install languages`):** Uses `asdf` (installed by `base`) to install specific versions of Node.js, Python, Java, Go. Edit `dev-languages.zsh` to customize versions or add languages.
* **VS Code Extensions (`./tany install vscode`):** Installs a curated list of useful VS Code extensions. Edit `vscode-extensions.zsh` to customize. Has an uninstaller (`./tany uninstall vscode`).
* **Security (`./tany security`):** **Interactive script** to set Git `user.name`/`user.email`, check/generate SSH keys, and log in to the `gh` CLI. **Not idempotent.** Run this manually after the base setup.

---

## 🏗️ Structure

The toolkit is organized into modular scripts managed by the main `tany` wrapper:

* **`lib_tany.sh`**: Shared library with helper functions, logging, and safety checks.
* **`tany`**: The main wrapper script to run installs/uninstalls.
* **`setup_ws_mac.zsh`**: Base installer (core terminal setup).
* **`uninstall_ws_mac.zsh`**: Base uninstaller.
* **`Brewfile`**: List of GUI apps for the 'apps' module.
* **`apps.zsh`**: GUI app installer.
* **`uninstall-apps.zsh`**: GUI app uninstaller.
* **`macos-defaults.zsh`**: Applies opinionated macOS system settings.
* **`undo-macos-defaults.zsh`**: Reverts macOS system settings.
* **`dev-languages.zsh`**: Installs language runtimes (uses asdf).
* **`security.zsh`**: Interactive script for security/identity setup.
* **`vscode-extensions.zsh`**: VS Code extension installer/uninstaller.

---

## ✅ Prerequisites

* **macOS:** Tested on macOS Monterey, Ventura, Sonoma. Should work on recent versions.
* **Internet Connection:** Required for downloading Homebrew, packages, and clones.
* **Xcode Command Line Tools:** Needed by Homebrew to compile certain packages. The `setup_ws_mac.zsh` script will check and prompt you to install them via a system dialog if they are missing (requires user interaction in the GUI).

---

## 🚀 Installation & Usage

1.  **Clone the Repository:**
    ```bash
    # Replace with your repo URL if you forked it
    git clone https://github.com/Sahilk5/ws_setup.git tany-workspace 
    cd tany-workspace
    ```
    *(Note: If you haven't set up SSH keys yet, use the HTTPS clone URL)*

2.  **Make Wrapper Executable:** (Only needed once)
    ```bash
    chmod +x tany
    ```

3.  **Run the Installer:** Use the `tany` wrapper script. It's recommended to start with the `base` module.

    ```bash
    # Display help and available commands/modules
    ./tany help

    # Install the core terminal setup (Recommended first step)
    ./tany install base

    # --- After installing base, complete the manual iTerm2 step below! ---

    # Optionally install other modules
    ./tany install apps
    ./tany install languages
    ./tany install vscode

    # Optionally apply macOS tweaks (Review first!)
    ./tany install defaults

    # Optionally run interactive security setup
    ./tany security

    # Or, install everything (non-interactive)
    ./tany install all
    # NOTE: 'install all' SKIPS the 'security' module, which must be run manually.

    # Preview changes without executing
    ./tany install base --dry-run
    ```

4.  **Manual iTerm2 Step (Crucial!):** After running `./tany install base`, you **must** configure iTerm2 to use the new profile:
    * Quit and relaunch iTerm2.
    * Open Settings (`Cmd + ,`).
    * Go to the `Profiles` tab.
    * Select `tany` from the list on the left.
    * Click `Other Actions...` at the bottom.
    * Select `Set as Default`.
    * Close settings and open a new iTerm2 window/tab. It should now have the Powerlevel10k prompt and Nerd Font icons.

5.  **Restart Shell:** For changes in `.zshrc` (like aliases, hooks) to take effect in existing shells, either restart iTerm2 or run `source ~/.zshrc`. New shells will load them automatically.

---

## 🛡️ Idempotency & Safety

* **Idempotent:** All automated install/uninstall scripts (except `security.zsh`) can be run multiple times safely. They check current state before acting.
* **Error Handling:** Scripts use `set -euo pipefail` and `TRAPZERR` to exit immediately on errors, preventing partial or corrupt states.
* **Atomic Writes:** Configuration files (`.p10k.zsh`, `.tmux.conf`, Neovim `init.vim`, iTerm profile, `rg` config) are written atomically using temp files. VS Code `settings.json` is backed up before modification.
* **Marker Blocks:** Changes made to `~/.zshrc` and `~/.zprofile` by the base script are enclosed in clearly marked `# >>> tany-setup BEGIN >>>` / `# <<< tany-setup END <<<` blocks. This allows for clean updates (`replace_block`) and reliable removal by the uninstaller.
* **Backups:** The base uninstaller (`uninstall_ws_mac.zsh`) creates timestamped backups of configuration files (e.g., `~/.tmux.conf.bak.YYYYMMDD-HHMMSS`) before removing them.
* **Network Retries:** `curl` and `git` operations include automatic retries for robustness against flaky connections.
* **Dry Run:** Most scripts support a `--dry-run` flag (passed via the `tany` wrapper) to preview actions without making changes.
* **Logging:** All scripts log their output (including errors) to timestamped files in your home directory (e.g., `~/.tany-setup-YYYYMMDD.log`).

---

## 🔧 Customization

* **GUI Apps:** Edit the `Brewfile`. Run `./tany install apps` to sync.
* **VS Code Extensions:** Edit the `EXTENSIONS` array in `vscode-extensions.zsh`. Run `./tany install vscode` to sync.
* **Language Versions:** Edit the version variables (e.g., `NODE_VERSION`) in `dev-languages.zsh`. Run `./tany install languages`.
* **Aliases:** Edit the `ZRC_PAYLOAD` block within `setup_ws_mac.zsh`. Re-run `./tany install base` to apply changes. Disable aliases temporarily with `export TANY_DISABLE_ALIASES=1`.
* **Powerlevel10k Prompt:** Run `p10k configure` in your terminal for an interactive wizard to customize the prompt appearance.
* **Neovim Config:** Edit `~/.config/nvim/init.vim`. Add plugins between `plug#begin()` and `plug#end()`, then run `:PlugInstall` inside Neovim.
* **tmux Config:** Edit `~/.tmux.conf`. Run `tmux source-file ~/.tmux.conf` or press `Prefix` + `r` (default: `Ctrl+b` then `r`) inside tmux to reload.

---

## ⏪ Uninstallation

Use the `tany` wrapper with the `uninstall` command or specific `--undo` flags where applicable.

```bash
# Uninstall the base setup
./tany uninstall base

# Uninstall the GUI apps
./tany uninstall apps

# Revert macOS defaults
./tany uninstall defaults

# Uninstall VS Code extensions
./tany uninstall vscode

# Uninstall everything possible
./tany uninstall all
```

*Note: `languages` and `security` do not have dedicated uninstallers.*

---

## 🩺 Troubleshooting

  * **Errors:** Check the error message and the relevant log file (e.g., `~/.tany-setup-*.log`) for details. The `TRAPZERR` function should indicate the script and line number where the error occurred.
  * **Command Not Found:** Ensure Homebrew is installed and its path is correctly added to `~/.zprofile` and sourced. Restarting your terminal is often required after the initial setup.
  * **VS Code `code` command:** If `vscode-extensions.zsh` fails, ensure the `code` command is in your PATH (Open VS Code -> `Cmd+Shift+P` -> "Shell Command: Install 'code' command in PATH").
  * **Permissions:** Some steps might require `sudo` (like Rosetta install). The script attempts `sudo -n` first for passwordless execution if possible.
  * **Network Issues:** Ensure you have a stable internet connection. `curl` and `git` commands have built-in retries.

---

## 📜 License

*(Consider adding a license file, e.g., MIT, Apache 2.0)*
Example: This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for details.
