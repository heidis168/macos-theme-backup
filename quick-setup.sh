#!/bin/bash
# SSH 远程快速恢复脚本
# 接收 tar.gz 压缩包，解压后执行引导安装
set -e

TARBALL="$HOME/macos-theme-backup.tar.gz"

if [ ! -f "$TARBALL" ]; then
    echo "❌ 请先将 macos-theme-backup.tar.gz 放到 $HOME/"
    echo "   scp macos-theme-backup.tar.gz user@new-host:~/"
    exit 1
fi

echo "📦 解压备份..."
cd "$HOME"
tar -xzf "$TARBALL"

echo "🚀 开始恢复..."
cd "$HOME/macos-theme"
chmod +x bootstrap.sh restore.sh
./bootstrap.sh

echo "✅ 全部完成！"
echo "请在桌面按 Alt+F2 → r → 回车 重启 Shell"
