# 实用工具集合

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](../LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/funnyzak/dotfiles)](https://github.com/funnyzak/dotfiles/commits/main)

此目录用于集中管理各类实用工具脚本，包括Python脚本和Shell脚本，方便在不同环境中快速使用这些工具来提高工作效率。

## 目录结构

```
utilities/
├── python/                    # Python脚本集合
│   └── bria/                  # Bria相关工具
│       └── background_remover.py  # 图片背景移除工具
└── shell/                     # Shell脚本集合
    └── batch_rename.sh        # 批量重命名工具
    └── cheatsheet.sh          # 命令行速查表工具
```

## 脚本使用说明

### Python工具

#### Bria图片背景移除工具

`background_remover.py` 是一个用于批量调用Bria服务的图片背景移除API的工具，支持处理本地图片文件和URL图片。

**文件位置**: `/utilities/python/bria/background_remover.py`

**功能**:
- 处理单个URL图片
- 批量处理URL文本文件中的图片
- 处理单个本地图片文件
- 批量处理文件夹中的图片
- 支持并发处理以提高效率

**使用方法**:

1. **命令行模式**:

```bash
# 使用API Token处理单个URL图片
python background_remover.py --api_token YOUR_API_TOKEN --url https://example.com/image.jpg --output_path ./output

# 处理URL文本文件
python background_remover.py --api_token YOUR_API_TOKEN --url_file ./urls.txt --output_path ./output

# 处理单个本地图片
python background_remover.py --api_token YOUR_API_TOKEN --file ./image.jpg

# 批量处理文件夹
python background_remover.py --api_token YOUR_API_TOKEN --batch_folder ./images --max_workers 8 --overwrite
```

2. **交互式模式**:

```bash
python background_remover.py
```

3. **远程执行**:

```bash
# 远程执行脚本(交互式模式)
python3 <(curl -s https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py)

# 远程执行脚本(命令行模式)
python3 <(curl -s https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/python/bria/background_remover.py) --api_token YOUR_API_TOKEN --url https://example.com/image.jpg --output_path ./output
```

**选项**:
- `--api_token, -t` : Bria API Token
- `--output_path, -o` : 输出路径(URL处理模式下必须)
- `--batch_folder, -b` : 批处理文件夹路径
- `--url_file, -u` : URL文本文件路径
- `--overwrite, -w` : 覆盖模式
- `--max_workers, -m` : 最大并发工作线程数 (默认: 4)
- `--url` : 单个URL处理
- `--file, -f` : 单个文件处理

**必要条件**:
1. 安装Python 3.x
2. 安装requests库 (`pip install requests`)
3. 获取Bria API Token (https://platform.bria.ai/console)

### Shell工具

#### 命令行速查表工具

`cheatsheet.sh` 是一个功能强大的命令行速查表工具，可以快速查询常用命令的语法和使用示例，支持多种不同类别的命令。

**文件位置**: `/utilities/shell/cheatsheet.sh`

**功能**:
- 提供交互式菜单界面，按类别展示所有命令
- 直接在命令行查看特定命令的速查表
- 支持本地缓存，提高访问速度(7天有效期)
- 自动检测并使用最佳URL来源(支持国内加速)
- 覆盖系统、网络、工具、安卓、媒体、包管理、运行时和Web服务器等多个类别的命令

**支持的命令类别**:
- 系统类: apt, awk, cat, chmod, chown, df, du, grep, ip, iptables, less, mount, nano, operators, rclone, rsync, systemctl, vim, watch, yum
- 网络类: curl, netstat, nmcli, tcpdump, wget
- 工具类: docker, git
- 安卓类: adb
- 媒体类: ffmpeg, Imagemagick
- 包管理类: npm, pnpm, yarn
- 运行时类: golang, java, node, python
- Web服务器类: caddy, nginx

**使用方法**:

1. **本地执行**:

```bash
# 赋予执行权限
chmod +x cheatsheet.sh

# 启动交互式菜单
./cheatsheet.sh

# 直接查看特定命令的速查表
./cheatsheet.sh git

# 列出所有支持的命令
./cheatsheet.sh -l
./cheatsheet.sh --list

# 显示帮助信息
./cheatsheet.sh -h
./cheatsheet.sh --help

# 使用自定义URL前缀
./cheatsheet.sh -u https://example.com/path/ git
```

2. **远程执行**:

```bash
# 启动交互式菜单
curl -sSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/shell/cheatsheet.sh -o cheatsheet.sh && chmod +x cheatsheet.sh && ./cheatsheet.sh

# 国内加速显示 git 命令速查表
curl -sSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/shell/cheatsheet.sh | bash -s -- git

# 显示帮助信息
curl -sSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/shell/cheatsheet.sh | bash -s -- -h

# 直接查看git命令速查表
curl -sSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/shell/cheatsheet.sh | bash -s -- git

# 列出所有支持的命令
curl -sSL https://raw.gitcode.com/funnyzak/dotfiles/raw/main/utilities/shell/cheatsheet.sh | bash -s -- -l
```

**选项**:
- `-h, --help`: 显示帮助信息
- `-l, --list`: 列出所有支持的命令
- `-u, --url URL`: 指定自定义URL前缀

**必要条件**:
1. Bash环境
2. curl 工具
3. less 命令

## 安装说明

### Python工具

1. 确保已安装Python 3.x
2. 根据具体脚本的需求安装必要的依赖包
3. 下载或克隆相关脚本到本地

### Shell工具

1. 下载相关脚本到本地
2. 赋予脚本执行权限:

```bash
chmod +x script_name.sh
```

## 贡献

欢迎提出问题或建议，可以通过GitHub Issues或Pull Requests进行贡献。

## 许可证

此项目采用 [MIT 许可证](../LICENSE)。
