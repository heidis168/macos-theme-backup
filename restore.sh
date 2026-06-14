#!/bin/bash
# ==========================================
# 桌面主题配置一键恢复脚本
# 恢复全部 GNOME 主题、Dock、GTK4 CSS、壁纸设置
# ==========================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/configs"

echo "🔄 正在恢复桌面主题配置..."

# === GTK/Shell/Interface (含 favorite-apps, 时钟, 触摸板等) ===
echo "🎨 恢复 GTK/Shell/界面设置..."
while IFS='=' read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    schema_key=$(echo "$line" | awk -F' = ' '{print $1}' | xargs)
    schema=$(echo "$schema_key" | awk '{print $1}')
    key=$(echo "$schema_key" | awk '{print $2}')
    # 值可能包含 = 和引号，用 shell 方式提取
    val=$(echo "$line" | sed "s/^[^=]* = //")
    [ -z "$schema" ] || [ -z "$key" ] || [ -z "$val" ] && continue
    gsettings set "$schema" "$key" "$val" 2>/dev/null && echo "  ✓ $schema_key" || echo "  ✗ $schema_key (跳过)"
done < "$CONFIG/gtk-settings.txt"

# === Dash-to-Dock ===
echo "📦 恢复 Dock 配置..."
DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
while IFS='=' read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*add-to-desktop ]] && break  # 到扩展列表就停
    key=$(echo "$line" | awk -F' = ' '{print $1}' | xargs)
    val=$(echo "$line" | sed "s/^[^=]* = //")
    [ -z "$key" ] || [ -z "$val" ] && continue
    gsettings set "$DOCK_SCHEMA" "$key" "$val" 2>/dev/null && echo "  ✓ $key" || echo "  ✗ $key (跳过)"
done < "$CONFIG/dock-settings.txt"

# === GTK4 CSS ===
if [ -d "$CONFIG/gtk4-css" ]; then
    echo "🎨 恢复 GTK4 CSS..."
    mkdir -p ~/.config/gtk-4.0
    for css in "$CONFIG/gtk4-css/"*.css; do
        [ -f "$css" ] || continue
        cp "$css" ~/.config/gtk-4.0/ 2>/dev/null
        echo "  ✓ $(basename "$css")"
    done
fi

# === 壁纸 ===
WP_DIR="$HOME/.local/share/backgrounds"
mkdir -p "$WP_DIR"
if [ -f "$CONFIG/wallpapers/MacTahoe-day.jpeg" ]; then
    cp "$CONFIG/wallpapers/MacTahoe-day.jpeg" "$WP_DIR/" 2>/dev/null
    echo "🖼️  壁纸已恢复"
fi

echo ""
echo "✅ 恢复完成！"
echo "请按 Alt+F2 → r → 回车 重启 GNOME Shell 使主题生效。"
echo ""
echo "⚠️  扩展需要自行安装："
echo "   - 系统扩展: gnome-shell-extension-manager (软件中心可装)"
echo "   - blur-my-shell: https://extensions.gnome.org/extension/3193/blur-my-shell/"
echo "   - logo-menu: 同上"
