#!/bin/bash
# Fix .zshrc PATH and error handling

HOME_DIR=$HOME
ZSHRC="$HOME_DIR/.zshrc"

# Backup
cp "$ZSHRC" "$ZSHRC.bak"

# Create fixed version
{
  echo 'export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"'
  grep -v '^export PATH' "$ZSHRC"
} > /tmp/zshrc.fixed

mv /tmp/zshrc.fixed "$ZSHRC"

# Fix direnv and zoxide eval lines to have error handling
sed -i 's/^eval "$(zoxide init zsh)"/eval "$(zoxide init zsh 2>\/dev\/null)" || true/' "$ZSHRC"
sed -i 's/^eval "$(direnv hook zsh)"/eval "$(direnv hook zsh 2>\/dev\/null)" || true/' "$ZSHRC"

echo "Fixed .zshrc - backup at $ZSHRC.bak"
echo "Now run: zsh to start using the fixed config"
