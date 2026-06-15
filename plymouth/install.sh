#!/bin/bash
# macOS 风格 Plymouth 启动界面安装
set -e

THEME_DIR="/usr/share/plymouth/themes/mac"

echo "==> 安装 macOS 风格 Plymouth 启动主题..."

# 复制主题文件
sudo cp -r "$(dirname "$0")/mac" /usr/share/plymouth/themes/

# 注册为可选 Plymouth 主题
sudo update-alternatives --install \
    /usr/share/plymouth/themes/default.plymouth \
    default.plymouth \
    "$THEME_DIR/mac.plymouth" \
    200

# 设为默认（优先级 200 > 系统默认 bgrt 110）
echo "==> 已设为默认启动主题"

# 更新 initramfs
sudo update-initramfs -u

echo "==> 完成，重启后生效"
