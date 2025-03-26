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

#### 批量重命名工具

`batch_rename.sh` 是一个用于批量重命名当前目录下文件的工具脚本。

**文件位置**: `/utilities/shell/batch_rename.sh`

**使用方法**:

```bash
./batch_rename.sh <模式> <替换文本>
```

**示例**:

```bash
# 将所有包含"test"的文件名替换为"demo"
./batch_rename.sh "test" "demo"
```

**功能**:
- 支持正则表达式匹配文件名
- 输出重命名过程的详细信息
- 简单易用，无需额外依赖

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
