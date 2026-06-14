#!/bin/bash
# ==========================================
# 桌面主题配置恢复脚本
# 从 git 备份中恢复全部 GNOME 主题设置
# ==========================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/configs"

echo "🔄 正在恢复桌面主题配置..."

# 读取并应用 GTK 主题设置
source <(grep -v '^#' "$CONFIG/gtk-settings.txt" | grep -v '^$' | grep -v '=== ' | sed 's/^ *//' | while IFS='=' read -r key val; do
    key=$(echo "$key" | xargs)
    val=$(echo "$val" | xargs)
    [ -z "$key" ] && continue
    echo "gsettings set $key $val 2>/dev/null"
done 2>/dev/null)

# 应用 Dock 设置
echo "📦 恢复 Dock 配置..."
while IFS='=' read -r key val; do
    key=$(echo "$key" | xargs)
    val=$(echo "$val" | xargs)
    [ -z "$key" ] && continue
    gsettings set org.gnome.shell.extensions.dash-to-dock "$key" "$val" 2>/dev/null || true
done < <(grep -E '^[a-z].*=' "$CONFIG/dock-settings.txt")

# 恢复 GTK4 CSS
if [ -d "$CONFIG/gtk4-css" ] && ls "$CONFIG/gtk4-css/"*.css &>/dev/null; then
    echo "🎨 恢复 GTK4 CSS..."
    mkdir -p ~/.config/gtk-4.0
    cp "$CONFIG/gtk4-css/"*.css ~/.config/gtk-4.0/
fi

echo "✅ 恢复完成！请按 Alt+F2 → r → 回车 重启 GNOME Shell 生效。"
