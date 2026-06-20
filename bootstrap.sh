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
    # ★ 让启动 logo 一开机就显示(而不是先跑一堆内核文字)：
    # 现象根因 = 显卡驱动(amdgpu/i915/nouveau)默认不在 initramfs 里，
    # 内核要等挂载根分区后才加载它，这之前 plymouth 没图形驱动只能显示文字。
    # 解决 = 把显卡驱动 + 固件强制打进 initramfs 早期加载。
    # ⚠ 注意 Ubuntu 26.04 用 dracut(不是 initramfs-tools)，必须用 dracut 语法。
    if command -v dracut >/dev/null 2>&1; then
        GPU_DRV=""
        lspci -k 2>/dev/null | grep -iA3 -E "vga|3d|display" | grep -qi amdgpu && GPU_DRV="amdgpu"
        lspci -k 2>/dev/null | grep -iA3 -E "vga|3d|display" | grep -qi i915   && GPU_DRV="$GPU_DRV i915"
        lspci -k 2>/dev/null | grep -iA3 -E "vga|3d|display" | grep -qi nouveau && GPU_DRV="$GPU_DRV nouveau"
        if [ -n "$GPU_DRV" ]; then
            sudo mkdir -p /etc/dracut.conf.d
            # force_drivers 让驱动早期加载；hostonly-no 时 dracut 会带上其固件
            printf 'force_drivers+=" %s "\nearly_microcode=yes\n' "$GPU_DRV" \
                | sudo tee /etc/dracut.conf.d/90-gpu-early.conf > /dev/null
            echo "  ✓ 显卡驱动 ($GPU_DRV) 设为 initramfs 早期加载"
        fi
        sudo dracut -f /boot/initrd.img-"$(uname -r)" "$(uname -r)" 2>&1 | tail -1
    else
        sudo update-initramfs -u 2>&1 | tail -1
    fi
    echo "  ✓ 已安装（重启生效）"
else
    echo "  ⚠ plymouth 主题缺失，跳过"
fi

# ====== 7. GDM 登录主题 ======
echo ""
echo "🔐 GDM 登录主题..."
if [ -f "$DIR/themes/MacTahoe-gtk-theme/tweaks.sh" ]; then
    # -g 装 GDM 登录主题，-i apple 把 Activities 按钮换成苹果图标
    # 注意：tweaks.sh 直接覆盖 Yaru 的 gnome-shell-theme.gresource，
    # 系统更新(gnome-shell/yaru-theme 升级)可能重置回 Ubuntu logo，届时重跑本步即可。
    sudo "$DIR/themes/MacTahoe-gtk-theme/tweaks.sh" -g -i apple 2>&1 | tail -2
    echo "  ✓ 已安装"
else
    echo "  ⚠ tweaks.sh 缺失，跳过"
fi

# ====== 7b. GDM 登录框底部中央 logo → 苹果 ======
# 登录框下方那个 logo 由 org.gnome.login-screen.logo 控制，
# Ubuntu 用 /usr/share/glib-2.0/schemas/10_ubuntu-settings.gschema.override
# 硬编码成 ubuntu-logo-text-dark.svg —— 优先级高于 greeter.dconf-defaults，
# 只能用标准 dconf profile(system-db:gdm) 才能覆盖。
echo ""
echo "🍎 GDM 底部 logo → 苹果..."
if [ -f "$DIR/configs/gdm-logo/apple-logo-white.svg" ]; then
    sudo cp "$DIR/configs/gdm-logo/apple-logo-white.svg" /usr/share/pixmaps/apple-logo-white.svg
    sudo chmod 644 /usr/share/pixmaps/apple-logo-white.svg
    sudo mkdir -p /etc/dconf/profile /etc/dconf/db/gdm.d
    printf 'user-db:user\nsystem-db:gdm\nfile-db:/usr/share/gdm/greeter-dconf-defaults\n' | sudo tee /etc/dconf/profile/gdm > /dev/null
    printf "[org/gnome/login-screen]\nlogo='/usr/share/pixmaps/apple-logo-white.svg'\n" | sudo tee /etc/dconf/db/gdm.d/01-apple-logo > /dev/null
    sudo dconf update
    echo "  ✓ 已设置（重启 GDM 生效）"
else
    echo "  ⚠ apple-logo-white.svg 缺失，跳过"
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
