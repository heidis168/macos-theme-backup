#!/bin/bash
set -e
THEME_DIR="/usr/share/plymouth/themes/mac-improved"
echo "==> 安装 macOS 风格 Plymouth 启动主题（光泽动画版）..."
sudo -S -p '' cp -r "$(dirname "$0")/mac" "$THEME_DIR"
sudo -S -p '' update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$THEME_DIR/mac.plymouth" 300
sudo -S -p '' update-initramfs -u
echo "==> 完成，重启后生效"
