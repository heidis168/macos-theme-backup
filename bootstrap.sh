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

# === 1. 系统依赖 ===
echo "📦 安装系统依赖..."
sudo apt update -qq
sudo apt install -y -qq gnome-shell-extensions sassc gedit gnome-tweaks gnome-shell-extension-manager 2>/dev/null || true

# === 2. 直接复制已编译主题（跳过不可靠的 install.sh） ===
echo ""
echo "🎨 安装 GTK 主题（预编译）..."
mkdir -p ~/.themes
cp -r "$DIR/themes-installed/"* ~/.themes/ 2>/dev/null
echo "  ✓ GTK 主题: $(ls ~/.themes/ 2>/dev/null | wc -l) 个变体"

# === 3. 图标主题（用 install.sh，这个可靠） ===
echo ""
echo "🎨 安装 MacTahoe 图标主题..."
cd "$DIR/themes/MacTahoe-icon-theme"
./install.sh 2>&1 | tail -3

# === 4. GNOME Shell 主题 ===
echo ""
echo "🎨 安装 GNOME Shell 主题..."
cd "$DIR/themes/MacTahoe-gtk-theme"
sudo ./install.sh -c light -b --round --shell -i apple 2>&1 | tail -5

# === 5. 扩展 ===
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

# === 6. 恢复全部配置（字体 + gsettings + dconf + 壁纸 + 扩展启用） ===
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
