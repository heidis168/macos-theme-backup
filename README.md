# 🖥️ macOS 风格桌面 — 完整离线备份

**来源**：Ubuntu 26.04 LTS (Resolute Raccoon) · GNOME Shell 50.1 · GTK 4.22 · Wayland  
**兼容**：Ubuntu 24.04+ / GNOME 46+

全新系统 → 一条命令恢复完全一致的 macOS 风格。

## 效果展示

![桌面](screenshots/2026-06-15-02-01-20.png)

![Dock 和窗口](screenshots/2026-06-15-02-01-26.png)

![应用概览](screenshots/2026-06-15-02-01-33.png)

![Nautilus 文件管理器](screenshots/2026-06-15-02-01-49.png)

![设置](screenshots/2026-06-15-02-01-59.png)

## 使用

```bash
git clone https://github.com/heidis168/macos-theme-backup.git
cd macos-theme-backup
chmod +x bootstrap.sh restore.sh
./bootstrap.sh
# 完成后：注销 → 重新登录
```

## 恢复内容

| 组件 | 说明 |
|------|------|
| GTK 主题 | MacTahoe + WhiteSur 24 变体 |
| 图标 | MacTahoe 128MB (含 cursor) |
| Shell 主题 | MacTahoe-Dark + Apple logo |
| GDM 登录 | MacTahoe GDM 主题 |
| 字体 | San Francisco Display + Text 21 otf |
| 扩展 | Blur My Shell, Logo Menu, sysmonitor 等 |
| gsettings | 55 界面/WM/Mutter + 48 Dock |
| dconf | 扩展内部配置 (blur/lockscreen/DING/…) |
| GTK4 CSS | 窗口透明度 + windows-assets |
| 壁纸 | MacTahoe-day.jpeg (3840×2160) |

## 依赖

`bootstrap.sh` 自动安装：`gnome-shell-extensions sassc gedit gnome-tweaks gnome-shell-extension-manager imagemagick`
