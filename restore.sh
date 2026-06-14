#!/bin/bash
# ==========================================
# 桌面主题配置一键恢复脚本
# 恢复全部 GNOME 主题、Dock、GTK4 CSS、壁纸、字体、dconf 扩展配置
# ==========================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/configs"

echo "🔄 正在恢复桌面主题配置..."

# === SF 字体 ===
if [ -d "$DIR/fonts/SanFrancisco" ]; then
    echo "🔤 安装 San Francisco 字体..."
    mkdir -p ~/.local/share/fonts/SanFrancisco
    cp "$DIR/fonts/SanFrancisco/"*.otf ~/.local/share/fonts/SanFrancisco/ 2>/dev/null
    fc-cache -f 2>/dev/null
    echo "  ✓ SF 字体已安装"
fi

# === GTK/Shell/Interface (含 favorite-apps, 时钟, 触摸板等) ===
echo "🎨 恢复 GTK/Shell/界面设置..."
while IFS='=' read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    schema_key=$(echo "$line" | awk -F' = ' '{print $1}' | xargs)
    schema=$(echo "$schema_key" | awk '{print $1}')
    key=$(echo "$schema_key" | awk '{print $2}')
    val=$(echo "$line" | sed "s/^[^=]* = //")
    [ -z "$schema" ] || [ -z "$key" ] || [ -z "$val" ] && continue
    gsettings set "$schema" "$key" "$val" 2>/dev/null && echo "  ✓ $schema_key" || echo "  ✗ $schema_key (跳过)"
done < "$CONFIG/gtk-settings.txt"

# === Dash-to-Dock (gsettings) ===
echo "📦 恢复 Dock 配置..."
DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"
while IFS='=' read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" =~ ^[[:space:]]*add-to-desktop ]] && break
    key=$(echo "$line" | awk -F' = ' '{print $1}' | xargs)
    val=$(echo "$line" | sed "s/^[^=]* = //")
    [ -z "$key" ] || [ -z "$val" ] && continue
    gsettings set "$DOCK_SCHEMA" "$key" "$val" 2>/dev/null && echo "  ✓ $key" || echo "  ✗ $key (跳过)"
done < "$CONFIG/dock-settings.txt"

# === dconf: 扩展配置 (blur-my-shell, logo-menu, ding, dash-to-dock 等) ===
echo "🔧 恢复扩展内部配置 (dconf)..."
if [ -f "$CONFIG/dconf/extensions.conf" ]; then
    dconf load /org/gnome/shell/extensions/ < "$CONFIG/dconf/extensions.conf"
    echo "  ✓ 扩展配置已恢复 (blur-my-shell, logo-menu, ding, appindicator ...)"
fi
if [ -f "$CONFIG/dconf/background.conf" ]; then
    dconf load /org/gnome/desktop/background/ < "$CONFIG/dconf/background.conf"
    echo "  ✓ 桌面背景 dconf 已恢复"
fi
if [ -f "$CONFIG/dconf/screensaver.conf" ]; then
    dconf load /org/gnome/desktop/screensaver/ < "$CONFIG/dconf/screensaver.conf"
    echo "  ✓ 锁屏 dconf 已恢复"
fi

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

WP_PATH="file://$WP_DIR/MacTahoe-day.jpeg"
gsettings set org.gnome.desktop.background picture-uri "'$WP_PATH'" 2>/dev/null
gsettings set org.gnome.desktop.background picture-uri-dark "'$WP_PATH'" 2>/dev/null
gsettings set org.gnome.desktop.screensaver picture-uri "'$WP_PATH'" 2>/dev/null
echo "🖼️  壁纸路径已修正: $WP_PATH"

# 强制确认路径（gsettings 可能被配置文件覆盖）
gsettings set org.gnome.desktop.background picture-uri "'$WP_PATH'"
gsettings set org.gnome.desktop.background picture-uri-dark "'$WP_PATH'"
gsettings set org.gnome.desktop.screensaver picture-uri "'$WP_PATH'"

# === 启用扩展 + 设置禁用列表 ===
echo "🔌 管理 Shell 扩展..."
LOCAL_EXTS=$(ls "$HOME/.local/share/gnome-shell/extensions/" 2>/dev/null | tr '\n' ' ')
SYS_EXTS=$(ls /usr/share/gnome-shell/extensions/ 2>/dev/null | tr '\n' ' ')
ALL_EXTS="$LOCAL_EXTS $SYS_EXTS"
ARRAY="["
for ext in $ALL_EXTS; do
    [ -z "$ext" ] && continue
    ARRAY="$ARRAY'$ext', "
done
ARRAY="${ARRAY%, }]"
gsettings set org.gnome.shell enabled-extensions "$ARRAY" 2>/dev/null
echo "  ✓ 已启用 $(echo $ALL_EXTS | wc -w) 个扩展"

echo ""
echo "✅ 恢复完成！"
echo "请按 Alt+F2 → r → 回车 重启 GNOME Shell 使主题生效。"
