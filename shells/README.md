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
│   │   ├── plugins/        # 自定义插件
│   │   └── themes/         # 自定义主题
│   └── tools/              # 工具脚本
│       ├── install_omz.sh  # 安装 Oh My Zsh 的脚本
│       └── install_omz_aliases.sh  # 下载别名文件的脚本
├── zsh/                    # Zsh 专用配置
```

## Oh My Zsh

### Oh My Zsh 配置

#### 自定义别名

Oh My Zsh 目录下包含了多种类型的别名文件，每个文件都聚焦于特定的功能领域:

- `archive_aliases.zsh`: 提供压缩和解压缩文件的快捷命令
- `brew_aliases.zsh`: Homebrew 相关的命令别名

如需新增或修改别名，可以在 `~/.oh-my-zsh/custom/aliases/` 目录下创建新的 `.zsh` 文件，或者直接编辑现有的别名文件。请在 `install_omz_aliases.sh` 脚本中添加新的别名文件路径，以便于下载和管理。

#### Zshrc 模板

```bash
# 远程安装模板
curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/zshrc.zsh-template -o ~/.zshrc
```

### Oh My Zsh 脚本

#### Oh My Zsh 安装维护

`install_omz.sh` 是一个用于安装、更新或卸载 Oh My Zsh 的工具脚本，支持多种安装模式和配置选项。

**文件位置**: `/shells/oh-my-zsh/tools/install_omz.sh`

**功能**:
- 自动安装或更新 Oh My Zsh
- 备份现有配置
- 强制重新安装
- 卸载 Oh My Zsh
- 自动切换默认 shell 至 zsh
- 支持自定义仓库 URL 和配置文件

**本地执行示例**:
```bash
# 基础安装
./install_omz.sh

# 无交互式安装
./install_omz.sh --yes

# 强制重新安装
./install_omz.sh --force

# 仅更新 Oh My Zsh
./install_omz.sh --update

# 卸载 Oh My Zsh
./install_omz.sh --uninstall
```

**远程执行示例**:
```bash
# 基础远程安装
curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz.sh | bash

# 无交互式远程安装
curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz.sh | bash -s -- --yes

# 强制重新安装
curl -fsSL https://raw.githubusercontent.com/funnyzak/dotfiles/refs/heads/main/shells/oh-my-zsh/tools/install_omz.sh | bash -s -- --force

# 卸载 Oh My Zsh
curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz.sh | bash -s -- --uninstall
```

**环境变量配置**:
```bash
# 使用自定义仓库 URL
OMZ_REPO_URL=https://github.com/ohmyzsh/ohmyzsh.git ./install_omz.sh

# 指定 zshrc 模板分支
OMZ_ZSHRC_BRANCH=develop ./install_omz.sh

# 指定自定义 zshrc 模板 URL
OMZ_ZSHRC_URL=https://example.com/my-zshrc.template ./install_omz.sh

# 自定义安装目录
OMZ_INSTALL_DIR=~/custom-omz ./install_omz.sh
```

**选项**:
- `-y, --yes`: 跳过所有确认提示
- `-s, --switch`: 自动将默认 shell 切换为 zsh
- `-f, --force`: 强制重新安装
- `-u, --update`: 仅更新已安装的 Oh My Zsh
- `-r, --uninstall`: 卸载 Oh My Zsh
- `-h, --help`: 显示帮助信息

#### Oh My Zsh 别名安装

`install_omz_aliases.sh` 是一个用于从远程仓库下载 Oh My Zsh 别名文件的工具脚本。

**文件位置**: `/shells/oh-my-zsh/tools/install_omz_aliases.sh`

**功能**:
- 下载指定的别名文件或默认的别名文件集合
- 支持自定义下载目录
- 支持自定义远程仓库 URL
- 可选是否覆盖现有文件
- 自动检测并使用最佳 URL 来源（支持国内加速）

**本地执行示例**:
```bash
# 安装所有默认别名文件
./install_omz_aliases.sh

# 安装指定的别名文件
./install_omz_aliases.sh git_aliases.zsh help_aliases.zsh

# 使用自定义 URL
./install_omz_aliases.sh --url https://example.com/aliases/

# 设置自定义默认列表
./install_omz_aliases.sh --default-list "git_aliases.zsh,help_aliases.zsh"

# 强制安装到指定目录
./install_omz_aliases.sh --directory ~/custom_aliases --force
```

**远程执行示例**:
```bash
# 下载所有别名文件
curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --force

# 下载特定的别名文件
curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- git_aliases.zsh system_aliases.zsh

# 下载指定 URL 的别名文件
curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --url https://example.com/aliases/ git_aliases.zsh

# 下载所有别名文件到指定目录
curl -fsSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/shells/oh-my-zsh/tools/install_omz_aliases.sh | bash -s -- --directory ~/custom_aliases --force
```

**选项**:
- `-h, --help`: 显示帮助信息
- `-d, --directory DIR`: 指定下载目录 (默认: $ZSH/custom/aliases/)
- `-n, --no-overwrite`: 不覆盖已存在的文件
- `-v, --verbose`: 启用详细输出
- `-f, --force`: 即使目录不存在也强制下载
- `-u, --url URL`: 指定自定义仓库 URL
- `-s, --default-list LIST`: 自定义默认别名列表（逗号分隔）
