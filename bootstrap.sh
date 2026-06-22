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

    # ★ 智能识别"接显示器的 GPU"，决定 plymouth 渲染策略：
    # 通过 /sys/class/drm/card*-* connector 的 status=connected 反查它所属的 card,
    # 再 readlink card 的驱动名 - 这就是真正承担显示输出的 GPU。
    PRIMARY_DRV=""
    for conn in /sys/class/drm/card*-*; do
        if [ "$(cat "$conn/status" 2>/dev/null)" = "connected" ]; then
            CARD=$(basename "$conn" | sed 's/-.*//')
            PRIMARY_DRV=$(readlink "/sys/class/drm/$CARD/device/driver" 2>/dev/null | xargs basename 2>/dev/null)
            break
        fi
    done
    NUM_CARDS=$(ls -d /sys/class/drm/card[0-9] 2>/dev/null | wc -l)
    echo "  ℹ 主显示 GPU: ${PRIMARY_DRV:-未知}, 物理显卡数: $NUM_CARDS"

    # 混合显卡(card0=amdgpu 无输出 + card1=i915 接屏)场景:
    # plymouth 24 默认遍历 /dev/dri/card0 → 选中 amdgpu → 但 amdgpu 没 connected output → 渲染失败 → 全程黑屏
    # 解法: plymouth 24 新选项 UseSimpledrm=yes,强制走 simpledrm framebuffer,跳过 DRM 协商
    USE_SIMPLEDRM="no"
    if [ "$NUM_CARDS" -gt 1 ] && [ "$PRIMARY_DRV" = "i915" ]; then
        USE_SIMPLEDRM="yes"
        echo "  ⚙ 检测到混合显卡且主显示由 i915 输出 → 启用 UseSimpledrm=yes"
    fi

    # 显式锁定主题 + 给 splash 显示时间 + 按需启用 UseSimpledrm
    sudo tee /etc/plymouth/plymouthd.conf > /dev/null <<PLYCONF
# Administrator customizations go in this file
[Daemon]
Theme=mac
ShowDelay=0
DeviceTimeout=8
UseSimpledrm=$USE_SIMPLEDRM
PLYCONF

    # ★ 让启动 logo 一开机就显示(而不是先跑一堆内核文字)：
    # 显卡驱动默认不在 initramfs 里，内核要等挂载根分区后才加载，这之前 plymouth 没图形驱动只能黑屏。
    # 解决 = 把"接显示器的 GPU 驱动"强制打进 initramfs 早期加载。
    # ⚠ 关键: 只 early-load 主显示卡的驱动!
    #   - AMD 单卡机: force_drivers="amdgpu"     ← 正常
    #   - 混合显卡(i915主+amdgpu副): force_drivers="i915" ← 不能加 amdgpu,否则它会抢走 /dev/dri/card0 让 plymouth 失败
    # Ubuntu 26.04 用 dracut(不是 initramfs-tools)。
    if command -v dracut >/dev/null 2>&1; then
        sudo mkdir -p /etc/dracut.conf.d
        # 删旧配置避免重复
        sudo rm -f /etc/dracut.conf.d/90-gpu-early.conf /etc/dracut.conf.d/91-plymouth-mac.conf
        # 写新配置: plymouth 模块 + 主显示卡驱动早期加载 + mac 主题文件
        sudo tee /etc/dracut.conf.d/91-plymouth-mac.conf > /dev/null <<DRACUTCONF
add_dracutmodules+=" plymouth "
force_drivers+=" ${PRIMARY_DRV:-i915} "
early_microcode=yes
install_items+=" /usr/share/plymouth/themes/mac/mac.plymouth /usr/share/plymouth/themes/mac/mac.script "
install_items+=" /usr/share/plymouth/themes/mac/boot.png /usr/share/plymouth/themes/mac/boot.svg "
install_items+=" /usr/share/plymouth/themes/mac/box.png /usr/share/plymouth/themes/mac/bullet.png "
install_items+=" /usr/share/plymouth/themes/mac/entry.png /usr/share/plymouth/themes/mac/lock.png "
install_items+=" /usr/share/plymouth/themes/mac/progress_bar.png /usr/share/plymouth/themes/mac/progress_box.png "
install_items+=" /usr/share/plymouth/themes/mac/shimmer.png "
DRACUTCONF
        echo "  ✓ 显卡驱动 (${PRIMARY_DRV:-i915}) + plymouth 模块设为 initramfs 早期加载"
        sudo dracut -f /boot/initrd.img-"$(uname -r)" "$(uname -r)" 2>&1 | tail -1
    else
        sudo update-initramfs -u 2>&1 | tail -1
    fi

    # 内核命令行: 启用 splash + rd.plymouth + 关闭控制台光标
    if [ -f /etc/default/grub ]; then
        sudo sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="quiet splash rd.plymouth=1 plymouth.enable=1 vt.global_cursor_default=0"|' /etc/default/grub
        if [ -d /boot/grub ]; then
            sudo grub-mkconfig -o /boot/grub/grub.cfg 2>&1 | tail -2
            echo "  ✓ GRUB 内核命令行已更新"
        fi
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
