#!/bin/bash
# ==========================================
# 全新系统引导安装脚本
# 克隆主题仓库 + 安装 + 恢复全部配置
# 用法: ./bootstrap.sh
# ==========================================
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🛠️  开始全新系统 macOS 风格安装..."
echo ""

# === 1. 安装依赖 ===
echo "📦 安装必要依赖..."
sudo apt update -qq
sudo apt install -y -qq git curl gnome-shell-extensions 2>/dev/null || true

# === 2. 克隆并安装 MacTahoe GTK/Shell 主题 ===
echo ""
echo "🎨 克隆 MacTahoe GTK 主题..."
if [ ! -d "/tmp/MacTahoe-gtk-theme" ]; then
    git clone https://github.com/vinceliuice/MacTahoe-gtk-theme.git --depth 1 /tmp/MacTahoe-gtk-theme
fi

echo "🔧 安装 GTK + Shell 主题 (Light 版本)..."
cd /tmp/MacTahoe-gtk-theme
./install.sh -c light -b --round -l --shell -i apple

# === 3. 克隆并安装图标主题 ===
echo ""
echo "🎨 克隆 MacTahoe 图标主题..."
if [ ! -d "/tmp/MacTahoe-icon-theme" ]; then
    git clone https://github.com/vinceliuice/MacTahoe-icon-theme.git --depth 1 /tmp/MacTahoe-icon-theme
fi

echo "🎨 安装图标主题..."
cd /tmp/MacTahoe-icon-theme
./install.sh

# === 4. 恢复全部桌面设置 ===
echo ""
echo "🔄 恢复全部桌面配置..."
cd "$DIR"
chmod +x restore.sh
./restore.sh

echo ""
echo "========================================"
echo "✅ 全新安装完成！"
echo ""
echo "💡 可选：安装 GDM 登录界面主题"
echo "   cd /tmp/MacTahoe-gtk-theme && sudo ./tweaks.sh -g"
echo ""
echo "⚠️  还需要手动安装以下扩展（去 extensions.gnome.org）："
echo "   - Blur My Shell (panels 毛玻璃效果)"
echo "   - Logo Menu (Apple logo)"
echo "   - System Monitor"
echo ""
echo "安装后：Alt+F2 → r → 回车 重启 Shell"
echo "========================================"
