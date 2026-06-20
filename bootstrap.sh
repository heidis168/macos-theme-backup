#!/bin/bash
# ==========================================
# macOS 风格桌面一键恢复
# 用法: tar -xzf backup.tar.gz && cd macos-theme && ./bootstrap.sh
# 完成后: 注销 → 重新登录
# ==========================================
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"

echo "🛠️  macOS 风格桌面 — 一键恢复"
echo "================================"
echo ""

# ====== 1. 系统依赖 ======
echo "📦 安装系统依赖..."
sudo apt update -qq
sudo apt install -y -qq \
    gnome-shell-extensions \
    sassc \
    gedit \
    gnome-tweaks \
    gnome-shell-extension-manager \
    imagemagick \
    2>/dev/null
echo "  ✓ 完成"

# ====== 2. GTK 主题（预编译，直接复制） ======
echo ""
echo "🎨 GTK 主题..."
mkdir -p ~/.themes
cp -r "$DIR/themes-installed/"* ~/.themes/ 2>/dev/null || true
echo "  ✓ $(ls ~/.themes/ 2>/dev/null | wc -l) 个变体"

# ====== 3. 扩展（先装扩展，Shell 主题安装会检测） ======
echo ""
echo "🔌 Shell 扩展..."
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"
for ext in "$DIR/extensions/"*; do
    [ -d "$ext" ] || continue
    cp -r "$ext" "$EXT_DIR/$(basename "$ext")"
    echo "  ✓ $(basename "$ext")"
done
# 编译 schemas 使扩展可被识别
for s in "$EXT_DIR"/*/schemas; do
    [ -d "$s" ] && glib-compile-schemas "$s" 2>/dev/null || true
done
echo "  ✓ schemas 已编译"

# ====== 4. 图标主题 ======
echo ""
echo "🎨 图标主题..."
if [ -d "$DIR/themes/MacTahoe-icon-theme" ]; then
    cd "$DIR/themes/MacTahoe-icon-theme"
    ./install.sh 2>&1 | tail -1
    cd "$DIR"
else
    echo "  ⚠ 图标源码缺失，跳过"
fi

# ====== 5. Shell 主题（含 apple logo, 模糊, 圆角, libadwaita） ======
echo ""
echo "🎨 Shell 主题..."
if [ -d "$DIR/themes/MacTahoe-gtk-theme" ]; then
    cd "$DIR/themes/MacTahoe-gtk-theme"
    ./install.sh -c light -b --round -l --shell -i apple 2>&1 | tail -2
    cd "$DIR"
else
    echo "  ⚠ Shell 主题源码缺失，跳过"
fi

# ====== 6. Plymouth 启动界面 ======
echo ""
echo "🍎 Plymouth 启动主题..."
if [ -d "$DIR/plymouth/mac" ]; then
    # ★ 关键：必须用标准目录名 mac，不能用 mac-improved 等自定义名！
    # Ubuntu 的 initramfs plymouth hook 只为标准目录名复制图片资源(boot.png 等)，
    # 非标准目录名会导致 .plymouth 被打包但所有 PNG 图片缺失 →
    # plymouth 找不到 boot.png 无法画苹果 logo → 回退显示 Ubuntu 默认 logo。
    sudo rm -rf /usr/share/plymouth/themes/mac
    sudo cp -r "$DIR/plymouth/mac" /usr/share/plymouth/themes/mac
    # 确保 mac.plymouth 内部 ImageDir/ScriptFile 指向标准 mac 目录
    sudo sed -i 's|/usr/share/plymouth/themes/mac-improved|/usr/share/plymouth/themes/mac|g' \
        /usr/share/plymouth/themes/mac/mac.plymouth
    sudo update-alternatives --install \
        /usr/share/plymouth/themes/default.plymouth \
        default.plymouth \
        /usr/share/plymouth/themes/mac/mac.plymouth \
        300
    sudo update-alternatives --set default.plymouth /usr/share/plymouth/themes/mac/mac.plymouth
    # 显式锁定主题 + 给 splash 显示时间(现代 NVMe 硬件启动极快，splash 易一闪而过)
    sudo tee /etc/plymouth/plymouthd.conf > /dev/null <<'PLYCONF'
# Administrator customizations go in this file
[Daemon]
Theme=mac
ShowDelay=0
DeviceTimeout=8
PLYCONF
    sudo update-initramfs -u 2>&1 | tail -1
    echo "  ✓ 已安装（重启生效）"
else
    echo "  ⚠ plymouth 主题缺失，跳过"
fi

# ====== 7. GDM 登录主题 ======
echo ""
echo "🔐 GDM 登录主题..."
if [ -f "$DIR/themes/MacTahoe-gtk-theme/tweaks.sh" ]; then
    sudo "$DIR/themes/MacTahoe-gtk-theme/tweaks.sh" -g 2>&1 | tail -2
    echo "  ✓ 已安装"
else
    echo "  ⚠ tweaks.sh 缺失，跳过"
fi

# ====== 8. 配置恢复（字体/壁纸/gsettings/dconf/GTK4 CSS/图标缓存） ======
echo ""
echo "🔄 配置恢复..."
chmod +x "$DIR/restore.sh"
"$DIR/restore.sh"

echo ""
echo "================================"
echo "✅ 安装完成"
echo ""
echo "⚠️  请立即：注销 → 重新登录"
echo "   主题、锁屏、Dock、模糊、按钮 才会全部生效"
echo "================================"
