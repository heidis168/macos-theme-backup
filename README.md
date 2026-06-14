# 🖥️ macOS 风格桌面 — 完整离线备份

全新 Ubuntu/GNOME 系统，**一条命令**恢复完全一致的 macOS 风格。

## 使用

```bash
tar -xzf macos-theme-backup-final.tar.gz
cd macos-theme
chmod +x bootstrap.sh restore.sh
./bootstrap.sh
# 完成后：注销 → 重新登录
```

## 恢复内容

- GTK 主题：MacTahoe + WhiteSur 24 变体
- 图标：MacTahoe 128MB
- Shell 主题：MacTahoe-Dark (apple logo)
- GDM 锁屏/登录主题
- 字体：San Francisco Display + Text 21otf
- 扩展：Blur My Shell, Logo Menu, sysmonitor 等
- 全部 gsettings (55 界面 + 48 Dock)
- dconf 扩展配置
- GTK4 CSS 透明度
- 壁纸
- 用户名自动适配 ($HOME)

## 依赖

需要网络安装的系统包（`bootstrap.sh` 自动处理）：
`gnome-shell-extensions sassc gedit gnome-tweaks gnome-shell-extension-manager imagemagick`
