# 🖥️ macOS 风格桌面配置备份

完整备份当前 GNOME 桌面主题、图标、Dock、GTK4 CSS 等全部配置，  
**支持全新系统一键恢复**。

## 目录结构

```
macos-theme/
├── README.md          # 本文件
├── bootstrap.sh       # 全新系统引导安装（克隆主题 + 安装 + 恢复）
├── restore.sh         # 仅恢复设置（主题/扩展需已安装）
└── configs/
    ├── gtk-settings.txt   # GTK/Shell/字体/时钟/触摸板等全部 gsettings
    ├── dock-settings.txt  # Dash-to-Dock 18 个 key + 26 个扩展列表
    ├── gtk4-css/          # GTK4 (libadwaita) 用户 CSS（4 文件，共 1.1MB）
    └── wallpapers/        # 当前壁纸 MacTahoe-day.jpeg
```

## 全新系统恢复

```bash
cd macos-theme
chmod +x bootstrap.sh restore.sh
./bootstrap.sh
# 然后 Alt+F2 → r → 回车
```

`bootstrap.sh` 自动完成：克隆 MacTahoe 主题仓库 → 安装 GTK/Shell 主题 → 安装图标 → 恢复全部 gsettings → 恢复 GTK4 CSS → 恢复壁纸

## 已有主题仅恢复设置

```bash
./restore.sh
```

## 依赖说明

需要手动安装的 GNOME Shell 扩展：
- **Blur My Shell** — 毛玻璃模糊效果（https://extensions.gnome.org/extension/3193/）
- **Logo Menu** — Apple logo 替代 Activities 文字
- 其余扩展来自 `gnome-shell-extensions` 包（bootstrap.sh 已自动安装）
