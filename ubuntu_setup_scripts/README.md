# Ubuntu Workspace Setup

Automate your Ubuntu/Debian development environment setup with this safe, idempotent, and modular toolkit. This is the Ubuntu equivalent of the macOS `mac_setup_scripts` folder.

**Automate your Ubuntu development environment setup with this safe, idempotent, and modular toolkit.**

This collection of scripts installs and configures a modern, productive command-line environment on Ubuntu/Debian Linux. It focuses on enhancing the core developer experience with powerful tools, sensible defaults, and quality-of-life improvements, while remaining robust and easy to manage.

## Philosophy

- **Modern Tools:** Leverages faster, more user-friendly CLI tools (like `eza`, `bat`, `rg`, `fzf`, `neovim`).
- **Consistency:** Aims for a consistent feel across terminal emulators, tmux, and VS Code's integrated terminal.
- **Safety First:** Designed to be idempotent (safe to re-run) and uses error trapping, backups, and atomic writes where possible.
- **Modularity:** Separates concerns into distinct scripts (base, apps, languages, security) managed by a central wrapper.
- **Minimal Base:** Keeps the core setup lean, allowing optional additions for specific language runtimes, or system tweaks.

## ✨ Features by Module

### Core (`./tany install base`)

- **System Dependencies:** Installs essential build tools and libraries via apt.
- **Modern Core Utilities:** Installs `eza`, `bat`, `fzf`, `btop`, `ripgrep`, `fd`, `tldr`, and wires in ergonomic aliases.
- **Zsh Environment:** Installs Zsh, Oh My Zsh, Powerlevel10k, Autosuggestions, Syntax Highlighting, improved history, and quality-of-life aliases.
- **Terminal Tools:** Configures Neovim (with starter config and plugins), tmux (with power user defaults), and lazygit.
- **Developer Helpers:** Enables zoxide, direnv, git-delta, and asdf.
- **Sensible Defaults:** Applies Git configuration tweaks, FZF defaults, and other productivity enhancements.
- **VS Code Prompt:** Optionally syncs the integrated terminal font to match the shell.

### Optional Modules

- **GUI Apps (`./tany install apps`):** Installs GUI applications (Docker, VS Code, Firefox) and cloud CLIs. Customize as needed.
- **Language Runtimes (`./tany install languages`):** Installs Node.js, Python, Java, and Go via `asdf`. Customize versions in `dev-languages.bash`.
- **VS Code Extensions (`./tany install vscode`):** Installs a curated list of VS Code extensions. Customize in `vscode-extensions.bash`. Uninstall with `./tany uninstall vscode`.
- **Security (`./tany security`):** Interactive helper for Git identity, SSH key creation, and GitHub CLI auth.

## 🏗️ Repository Layout

```
ubuntu_setup_scripts/
  tany                   # Wrapper entry point
  lib_tany.sh            # Shared helpers (logging, dry-run, atomics, etc.)
  setup_ws_ubuntu.bash   # Core installer
  uninstall_ws_ubuntu.bash # Core uninstaller
  apps.bash              # Install GUI apps
  uninstall-apps.bash    # Remove GUI apps
  dev-languages.bash     # Install runtimes via asdf
  security.bash          # Interactive security helper
  vscode-extensions.bash # Manage VS Code extensions
  README.md              # This file
```

All scripts log to timestamped files in your home directory (for example, `~/.tany-setup-YYYYMMDD.log`).

## ✅ Prerequisites

- Ubuntu 20.04 LTS or newer (tested on recent releases).
- Internet connection for downloads.
- `sudo` access for package installation.

## 🚀 Usage

Clone the repository and run the wrapper:

```bash
git clone https://github.com/Sahilk5/ws_setup.git tany-workspace
cd tany-workspace/ubuntu_setup_scripts
chmod +x tany *.bash lib_tany.sh  # Make scripts executable
./tany help
```

Typical workflow:

```bash
./tany install base          # Core environment
./tany security              # Interactive identity setup
./tany install apps          # Optional GUI additions
./tany install languages     # Install language runtimes
./tany install vscode        # Install VS Code extensions
```

**Dry Run:** Append `--dry-run` to preview actions, e.g. `./tany install base --dry-run`.

**All-in-One:** `./tany install all`

## 📋 What Gets Installed

### Core (base module)
- **Package Manager:** apt-get (system default)
- **Build Tools:** build-essential, git, curl, wget, python3
- **Modern CLI Tools:** eza, bat, fzf, btop, ripgrep, fd, lazygit, direnv, zoxide
- **Editor:** Neovim (with vim-plug and starter plugins)
- **Shell:** Zsh, Oh My Zsh, Powerlevel10k, autosuggestions, syntax-highlighting
- **Multiplexer:** tmux (with custom config)
- **Language Manager:** asdf (for Node.js, Python, Java, Go)

### Apps (apps module)
- Docker Desktop / docker.io
- VS Code
- Firefox
- AWS CLI
- GitHub CLI
- Git

### Languages (languages module via asdf)
- Node.js (v20.17.0, customizable)
- Python (v3.12.6, customizable)
- Java (optional, via asdf)
- Go (optional, via asdf)

### VS Code Extensions
- C/C++ Tools
- Prettier
- ESLint
- GitHub Copilot
- GitLens
- Docker
- GitHub Theme
- Python & Pylance

## 🔧 Customization

### Changing Language Versions

Edit `dev-languages.bash` and modify:
```bash
NODE_VERSION="20.17.0"
PYTHON_VERSION="3.12.6"
```

### Adding/Removing VS Code Extensions

Edit `vscode-extensions.bash` and modify the `EXTENSIONS` array:
```bash
EXTENSIONS=(
  "ms-vscode.cpptools"
  "your.extension"
  # ...
)
```

### Changing Installed Applications

Edit `apps.bash` to add/remove APT packages:
```bash
apt_install "your-package" "another-package"
```

## 📝 Uninstalling

To undo changes:

```bash
./tany uninstall base          # Remove core setup
./tany uninstall apps          # Remove applications
./tany uninstall vscode        # Remove VS Code extensions
```

## 🐛 Troubleshooting

### Permission Denied
Make scripts executable:
```bash
chmod +x tany *.bash lib_tany.sh
```

### apt-get Errors
The script automatically runs `sudo apt-get update` before installing. If you encounter persistent issues:
```bash
sudo apt-get update
sudo apt-get upgrade
```

### Zsh Not as Default Shell
The script prompts to set Zsh as default. If skipped, do manually:
```bash
chsh -s /bin/zsh
```

### asdf Plugin Installation Issues
Ensure asdf is sourced in your shell:
```bash
. ~/.asdf/asdf.sh
asdf plugin list
```

## 📚 Documentation

For detailed information about the macOS version (which this is adapted from), see `../mac_setup_scripts/README.md`.

## 🤝 Contributing

Feel free to customize scripts for your environment. This setup is designed to be modular and extensible.

## 📄 License

See LICENSE in the root of the repository.
