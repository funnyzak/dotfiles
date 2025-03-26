# dotfiles

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

`dotfiles` 仓库用于集中管理个人使用的配置脚本、系统设置、实用工具脚本和相关文档，方便备份、同步和复用开发环境及常用工具的配置。

> **注意：** 本项目主要为个人使用设计，可能不完全适合所有用户。请根据自身需求进行修改和调整。

**CDN 地址：**

*   jsdelivr: [`https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/`](https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/)
*   GitHub raw: [`https://raw.githubusercontent.com/funnyzak/dotfiles/main/`](https://raw.githubusercontent.com/funnyzak/dotfiles/main/)

## 目录结构

采用以下目录结构来组织不同类型的脚本和文档，以便清晰管理和快速查找：

```
dotfiles/
├── shells/              # Shell 配置集合
│   ├── oh-my-zsh/       # Oh My Zsh 相关配置
│   │   └── custom/      # Oh My Zsh 自定义内容
│   │       ├── aliases/
│   │       ├── plugins/
│   │       └── themes/
│   ├── zsh/       # Zsh 配置
├── system/              # Linux 系统设置脚本
│   ├── config/          # 系统配置文件相关的脚本 (如 sysctl, bashrc)
│   │   ├── bashrc.sh
│   │   └── sysctl.conf
│   ├── automation/      # 系统自动化脚本 (如定时任务，监控脚本)
│   │   └── daily_backup.sh
│   └── setup/         # 系统初始化或安装脚本
│       └── install_tools.sh
├── utilities/           # 通用脚本 (跨平台或不特定于应用的脚本)
│   ├── shell/           # Shell 脚本
│   │   └── batch_rename.sh
│   ├── python/          # Python 脚本
│   │   └── process_data.py
│   ├── ...              # 其他语言或类型的通用脚本目录
├── docs/                # 文档
│   ├── help/            # 应用或工具的帮助文档
│   │   ├── app-x-usage.md
│   │   └── cli-tool-tips.md
│   ├── general/         # 通用文档 
│   │   ├── linux-command-tips.md
│   │   └── git-workflow.md
│   ├── templates/       # 文档模板
│   │   └── report-template.md
```

## 许可证

采用 [MIT License](LICENSE) 开源许可证。 