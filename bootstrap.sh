#!/bin/bash
# ==========================================
# 全新系统引导安装脚本（完全离线）
# 从本地打包的主题/扩展/字体/配置 一键恢复
# 用法: ./bootstrap.sh
# ==========================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🛠️  开始全新系统 macOS 风格安装（离线模式）..."
echo ""

# === 1. 安装系统依赖 ===
echo "📦 安装系统依赖..."
sudo apt update -qq
sudo apt install -y -qq gnome-shell-extensions 2>/dev/null || true

# === 2. 安装 MacTahoe GTK/Shell 主题（本地源码） ===
echo ""
echo "🎨 安装 MacTahoe GTK + Shell 主题..."
cd "$DIR/themes/MacTahoe-gtk-theme"
./install.sh -c light -b --round -l --shell -i apple

# === 3. 安装图标主题（本地源码） ===
echo ""
echo "🎨 安装 MacTahoe 图标主题..."
cd "$DIR/themes/MacTahoe-icon-theme"
./install.sh

# === 4. 安装 shell 扩展（本地备份） ===
echo ""
echo "🔌 安装 GNOME Shell 扩展..."
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"
for ext in "$DIR/extensions/"*; do
    [ -d "$ext" ] || continue
    extname=$(basename "$ext")
    cp -r "$ext" "$EXT_DIR/$extname"
    echo "  ✓ $extname"
done

# === 5. 运行 restore.sh（字体 + 设置 + 壁纸 + 扩展管理） ===
echo ""
echo "🔄 恢复全部配置..."
cd "$DIR"
chmod +x restore.sh
./restore.sh

echo ""
echo "========================================"
echo "✅ 全新安装完成！"
echo ""
echo "💡 可选：安装 GDM 登录界面主题"
echo "   cd themes/MacTahoe-gtk-theme && sudo ./tweaks.sh -g"
echo ""
echo "重启 Shell: Alt+F2 → r → 回车"
echo "========================================"
