#!/bin/bash

# Tmux Setup
sudo apt install -y tmux

tmux_conf_file=~/.tmux.conf

cat > $tmux_conf_file <<EOF
set -g prefix \`
unbind C-b # C-b即Ctrl+b键，unbind意味着解除绑定
bind \` send-prefix # 绑定 \` 为新的指令前缀

set -g mouse on
run-shell ~/.tmux/plugins/tmux-resurrect/resurrect.tmux
set -g @resurrect-capture-pane-contents 'on' # 开启恢复面板内容功能
set -g @continuum-save-interval '5'
set -g @continuum-restore 'on' # 启用自动恢复
set-option -g history-limit 10000

# 按下R键时，重新载入 tmux 配置文件
bind-key r source-file ~/.tmux.conf \; display-message "~/.tmux.conf reloaded"
# 按下M键时，它会创建一个新的水平面板并在其中打开 vim 编辑器
bind-key M split-window -h "vim ~/.tmux.conf"
EOF

echo "Config written to $tmux_conf_file"
