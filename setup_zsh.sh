#!/bin/bash

sudo apt update
sudo apt install git curl wget unzip locales ffmpeg libsm6 libxext6 python3-dev python3-pip python3-setuptools -y
locale-gen en_US.UTF-8

sudo apt install -y zsh

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"  "" --unattended


# Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions.git $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting
git clone https://github.com/so-fancy/diff-so-fancy.git $HOME/.oh-my-zsh/custom/plugins/diff-so-fancy

sudo apt install bat
mkdir -p ~/.local/bin
ln -s /usr/bin/batcat ~/.local/bin/bat

pip3 install thefuck --user

sed -i '1s|^|export PATH="$HOME/.local/bin/:$PATH:$HOME/.oh-my-zsh/custom/plugins/diff-so-fancy"\n|' ~/.zshrc
sed -i '1s/^/eval $(thefuck --alias)\n /' ~/.zshrc

git config --global core.pager "diff-so-fancy | less --tabs=4 -RF"
git config --global interactive.diffFilter "diff-so-fancy --patch"
git config --global color.ui true

git config --global color.diff-highlight.oldNormal    "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal    "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"

git config --global color.diff.meta       "11"
git config --global color.diff.frag       "magenta bold"
git config --global color.diff.func       "146 bold"
git config --global color.diff.commit     "yellow bold"
git config --global color.diff.old        "red bold"
git config --global color.diff.new        "green bold"
git config --global color.diff.whitespace "red reverse"

# Enable features
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting extract z)/' ~/.zshrc # enable git plugin
sed -i 's/#\s*\(ZSH_THEME="gallois"\)/\1/' ~/.zshrc # change theme
echo 'export TERM=xterm-256color' >> ~/.zshrc # enable 256 color support
echo 'setopt histignorealldups' >> ~/.zshrc # ignore duplicate commands in history
echo 'setopt share_history' >> ~/.zshrc # share command history between shells
echo 'export LC_ALL=en_US.UTF-8' >> ~/.zshrc # change language settings
echo 'export LANG=en_US.UTF-8' >> ~/.zshrc # change language settings
echo 'alias dircount="find . -type f | wc -l"' >> ~/.zshrc # Add folder count alias
echo 'alias filecount="ls | wc -l"' >> ~/.zshrc # Add file count alias
echo 'alias cat="batcat --paging=never -p"' >> ~/.zshrc

chsh -s $(which zsh)

if [[ "$1" == "dbz" ]]; then
  git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
  sed -i '/ZSH_THEME=/c\ZSH_THEME="powerlevel10k/powerlevel10k"' ~/.zshrc
fi
