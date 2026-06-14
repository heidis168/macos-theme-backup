#!/bin/bash
# ==========================================
# macOS 风格桌面一键恢复（全新系统 → 完全一致）
# 用法: ./bootstrap.sh
# 完成后: 注销重新登录
# ==========================================
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🛠️  macOS 风格桌面 — 一键恢复"
echo "================================"
echo ""

# 1. 依赖
echo "📦 系统依赖..."
sudo apt update -qq && sudo apt install -y -qq gnome-shell-extensions sassc gedit gnome-tweaks gnome-shell-extension-manager imagemagick 2>/dev/null
echo "  ✓ 完成"

# 2. GTK 主题（预编译，跳过不可靠的 install.sh）
echo ""
echo "🎨 GTK 主题..."
mkdir -p ~/.themes && cp -r "$DIR/themes-installed/"* ~/.themes/ 2>/dev/null
echo "  ✓ $(ls ~/.themes/ 2>/dev/null | wc -l) 个变体"

# 3. 图标主题
echo ""
echo "🎨 图标主题..."
cd "$DIR/themes/MacTahoe-icon-theme" && ./install.sh 2>&1 | tail -1
cd "$DIR"

# 4. Shell 主题 (需要 sudo 安装到 /usr/share)
echo ""
echo "🎨 Shell 主题..."
cd "$DIR/themes/MacTahoe-gtk-theme"
./install.sh -c light -b --round -l --shell -i apple 2>&1 | tail -2
cd "$DIR"

# 5. GDM 登录主题
echo ""
echo "🔐 GDM 登录主题..."
sudo ./themes/MacTahoe-gtk-theme/tweaks.sh -g 2>&1 | tail -2
echo "  ✓ 已安装"

# 6. 扩展
echo ""
echo "🔌 Shell 扩展..."
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"
for ext in "$DIR/extensions/"*; do
    [ -d "$ext" ] && cp -r "$ext" "$EXT_DIR/$(basename "$ext")" && echo "  ✓ $(basename "$ext")"
done

# 7. 编译扩展 schemas
for ext in "$EXT_DIR"/*/schemas; do
    [ -d "$ext" ] && glib-compile-schemas "$ext" 2>/dev/null
done

# 8. 恢复全部配置（gsettings + dconf + 字体 + 壁纸 + GTK4 CSS）
echo ""
echo "🔄 配置恢复..."
chmod +x "$DIR/restore.sh"
"$DIR/restore.sh"

echo ""
echo "================================"
echo "✅ 安装完成"
echo ""
echo "⚠️  请立即执行：注销 → 重新登录"
echo "   所有主题、锁屏、Dock、模糊效果才会生效"
echo "================================"
