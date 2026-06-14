# 🖥️ macOS 风格桌面配置备份

备份当前 GNOME 桌面主题、图标、Dock、GTK4 CSS 等全部配置，**方便以后一键恢复**。

## 目录结构

```
macos-theme/
├── README.md          # 本文件
├── restore.sh         # 恢复脚本
└── configs/
    ├── gtk-settings.txt   # GTK/Shell/字体/壁纸设置
    ├── dock-settings.txt  # Dock 配置 + 已安装的扩展列表
    └── gtk4-css/          # GTK4 (libadwaita) 用户 CSS
```

## 恢复方法

```bash
cd macos-theme
chmod +x restore.sh
./restore.sh
# 然后按 Alt+F2 → r → 回车重启 Shell
```

## 导出说明

- 导出的只是 **gsettings 键值对**，不依赖特定主题包
- 恢复时依赖对应主题/图标/扩展已安装
- 扩展列表在 `dock-settings.txt` 末尾，手动安装缺失的扩展即可
