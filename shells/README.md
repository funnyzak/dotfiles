# Shell 配置管理

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

此目录用于集中管理各种 shell 相关的配置文件、别名设置、插件和主题，便于在不同环境中快速部署个人的 shell 开发环境。

## 目录结构

```
shells/
├── oh-my-zsh/              # Oh My Zsh 相关配置
│   ├── README.md           # Oh My Zsh 配置说明文档
│   ├── zshrc.zsh-template  # Zsh 配置模板文件
│   ├── custom/             # Oh My Zsh 自定义内容
│   │   ├── aliases/        # 自定义别名集合
│   │   │   ├── archive_aliases.zsh    # 归档相关别名
│   │   │   ├── brew_aliases.zsh       # Homebrew 相关别名
│   │   │   ├── bria_aliases.zsh       # Bria 相关别名
│   │   │   ├── dependency_aliases.zsh # 依赖管理相关别名
│   │   │   ├── directory_aliases.zsh  # 目录操作相关别名
│   │   │   ├── docker_aliases.zsh     # Docker 相关别名
│   │   │   ├── filesystem_aliases.zsh # 文件系统相关别名
│   │   │   ├── git_aliases.zsh        # Git 相关别名
│   │   │   ├── help_aliases.zsh       # 帮助相关别名
│   │   │   ├── image_aliases.zsh      # 图像处理相关别名
│   │   │   ├── mc_aliases.zsh         # MC 相关别名
│   │   │   ├── network_aliases.zsh    # 网络相关别名
│   │   │   ├── notification_aliases.zsh # 通知相关别名
│   │   │   ├── pdf_aliases.zsh        # PDF 处理相关别名
│   │   │   ├── system_aliases.zsh     # 系统操作相关别名
│   │   │   ├── tcpdump_aliases.zsh    # Tcpdump 相关别名
│   │   │   ├── video_aliases.zsh      # 视频处理相关别名
│   │   │   └── zsh_config_aliases.zsh # Zsh 配置相关别名
│   │   ├── plugins/        # 自定义插件
│   │   └── themes/         # 自定义主题
│   └── tools/              # 工具脚本
│       └── install_omz_aliases.sh  # 下载别名文件的脚本
├── zsh/                    # Zsh 专用配置
```

## 脚本使用说明

### Oh My Zsh 配置

#### 别名下载工具

`install_omz_aliases.sh` 是一个用于从远程仓库下载 Oh My Zsh 别名文件的工具脚本。

- [ ] 支持通过环境变量设置下载地址
**文件位置**: `/shells/oh-my-zsh/tools/install_omz_aliases.sh`

**远程执行示例**:
```bash
curl -fsSL https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force
```

**使用方法**:
```bash
./install_omz_aliases.sh [选项] [别名文件...]
```

**选项**:
- `-h, --help`: 显示帮助信息
- `-d, --directory DIR`: 指定下载目录 (默认: $ZSH/custom/aliases/)
- `-n, --no-overwrite`: 不覆盖已存在的文件
- `-l, --list`: 列出可用的别名文件
- `-v, --verbose`: 启用详细输出
- `-f, --force`: 即使目录不存在也强制下载

如果未指定别名文件，将下载所有可用的别名文件。

**示例**:
1. 列出所有可用的别名文件:
```bash
./install_omz_aliases.sh --list
```

2. 下载特定的别名文件:
```bash
./install_omz_aliases.sh git_aliases.zsh system_aliases.zsh
```

3. 下载所有别名文件到指定目录:
```bash
./install_omz_aliases.sh --directory ~/custom_aliases --force
```

#### 自定义别名

Oh My Zsh 目录下包含了多种类型的别名文件，每个文件都聚焦于特定的功能领域:

- `archive_aliases.zsh`: 提供压缩和解压缩文件的快捷命令
- `brew_aliases.zsh`: Homebrew 相关的命令别名

如需新增或修改别名，可以在 `~/.oh-my-zsh/custom/aliases/` 目录下创建新的 `.zsh` 文件，或者直接编辑现有的别名文件。请在 `install_omz_aliases.sh` 脚本中添加新的别名文件路径，以便于下载和管理。

## 安装说明

### Oh My Zsh 配置

1. 确保已安装 [Oh My Zsh](https://ohmyz.sh/)
2. 下载并应用配置模板:
```bash
curl -fsSL https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/zshrc.zsh-template > ~/.zshrc
```
3. 下载别名文件:
```bash
# 下载所有别名文件
curl -fsSL https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force

curl -fsSL https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- -s git_aliases.zsh

curl -fsSL https://cdn.jsdelivr.net/gh/funnyzak/dotfiles@main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --url https://example.com/aliases/ git_aliases.zsh
```

## 贡献

欢迎提出问题或建议，可以通过 GitHub Issues 或 Pull Requests 进行贡献。

## 许可证

此项目采用 [MIT 许可证](../LICENSE)。
