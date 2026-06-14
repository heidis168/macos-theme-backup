# 🖥️ macOS 风格桌面配置 — 完整离线备份

全新 Ubuntu/GNOME 系统，**无需联网**，一键恢复到与当前完全一致的 macOS 风格桌面。

## 目录结构

```
macos-theme/
├── bootstrap.sh          # 全新系统一键安装（离线）
├── restore.sh            # 仅恢复 gsettings 设置
├── themes/               # MacTahoe 主题源码（108MB 离线打包）
│   ├── MacTahoe-gtk-theme/
│   └── MacTahoe-icon-theme/
├── extensions/           # 关键 shell 扩展（blur-my-shell 等）
│   ├── blur-my-shell@aunetx/
│   ├── logomenu@aryan_k/
│   └── sysmonitor@talhasiddique7/
└── configs/
    ├── gtk-settings.txt      # 40+ gsettings 键值对
    ├── dock-settings.txt     # 18 个 Dock key + 26 个扩展列表
    ├── gtk4-css/             # GTK4 窗口透明度 CSS
    └── wallpapers/           # 当前壁纸
```

## 全新系统恢复

```bash
cd macos-theme
chmod +x bootstrap.sh && ./bootstrap.sh
# Alt+F2 → r → 回车
```

bootstrap.sh 自动执行：安装 gnome-shell-extensions → 本地编译安装 GTK 主题 → 安装图标 → 复制扩展 → 恢复全部设置 → 恢复壁纸。

**完全离线**，不依赖 GitHub 或任何网络。

## 已有主题仅恢复设置

```bash
./restore.sh
```
