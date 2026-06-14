#!/bin/bash
# ==========================================
# 桌面主题配置一键恢复脚本
# 恢复全部 GNOME 主题、Dock、GTK4 CSS、壁纸、字体、dconf 扩展配置
# 自动适配任意用户名
# ==========================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/configs"

echo "🔄 正在恢复桌面主题配置..."

# === 预处理：替换配置文件中的硬编码路径为当前用户 ===
echo "🔧 适配当前用户路径..."
TMP_CONFIG="/tmp/macos-theme-restore-$$"
mkdir -p "$TMP_CONFIG"

# 复制并替换 gtk-settings.txt
sed "s|/home/heidis|$HOME|g" "$CONFIG/gtk-settings.txt" > "$TMP_CONFIG/gtk-settings.txt"

# 复制并替换 dconf 文件
for f in background.conf screensaver.conf full-dconf.conf; do
    if [ -f "$CONFIG/dconf/$f" ]; then
        sed "s|/home/heidis|$HOME|g" "$CONFIG/dconf/$f" > "$TMP_CONFIG/$f"
    fi
done

# === SF 字体 ===
if [ -d "$DIR/fonts/SanFrancisco" ]; then
    echo "🔤 安装 San Francisco 字体..."
    mkdir -p ~/.local/share/fonts/SanFrancisco
    cp "$DIR/fonts/SanFrancisco/"*.otf ~/.local/share/fonts/SanFrancisco/ 2>/dev/null
    fc-cache -f 2>/dev/null
    echo "  ✓ SF 字体已安装"
fi

# === GTK/Shell/Interface ===
echo "🎨 恢复 GTK/Shell/界面设置..."
while IFS='=' read -r line; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    schema_key=$(echo "$line" | awk -F' = ' '{print $1}' | xargs)
    schema=$(echo "$schema_key" | awk '{print $1}')
    key=$(echo "$schema_key" | awk '{print $2}')
    val=$(echo "$line" | sed "s/^[^=]* = //")
    [ -z "$schema" ] || [ -z "$key" ] || [ -z "$val" ] && continue
    gsettings set "$schema" "$key" "$val" 2>/dev/null && echo "  ✓ $schema_key" || echo "  ✗ $schema_key (跳过)"
done < "$TMP_CONFIG/gtk-settings.txt"

# === Dash-to-Dock ===
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

# === dconf: 扩展配置 ===
echo "🔧 恢复扩展内部配置 (dconf)..."
if [ -f "$TMP_CONFIG/full-dconf.conf" ]; then
    dconf load / < "$TMP_CONFIG/full-dconf.conf"
    echo "  ✓ 完整 dconf 已恢复（路径已适配当前用户）"
elif [ -f "$CONFIG/dconf/extensions.conf" ]; then
    dconf load /org/gnome/shell/extensions/ < "$CONFIG/dconf/extensions.conf"
    echo "  ✓ 扩展配置已恢复"
fi

# 额外确保背景/锁屏 dconf
if [ -f "$TMP_CONFIG/background.conf" ]; then
    dconf load /org/gnome/desktop/background/ < "$TMP_CONFIG/background.conf"
fi
if [ -f "$TMP_CONFIG/screensaver.conf" ]; then
    dconf load /org/gnome/desktop/screensaver/ < "$TMP_CONFIG/screensaver.conf"
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

# 修正确保壁纸路径
WP_PATH="file://$WP_DIR/MacTahoe-day.jpeg"
gsettings set org.gnome.desktop.background picture-uri "'$WP_PATH'"
gsettings set org.gnome.desktop.background picture-uri-dark "'$WP_PATH'"
gsettings set org.gnome.desktop.screensaver picture-uri "'$WP_PATH'"
echo "🖼️  壁纸: $WP_PATH"

# === 启用扩展（使用配置文件精确列表，不自动全开） ===
echo "🔌 管理 Shell 扩展..."
# gtk-settings.txt 中已设置 enabled-extensions + disabled-extensions
# 无需额外操作，gsettings 恢复步骤已处理
echo "  ✓ 扩展启用/禁用已按配置精确恢复"

# === 清理 ===
rm -rf "$TMP_CONFIG"

echo ""
echo "✅ 恢复完成！"
echo "请注销重新登录使全部设置生效。"
