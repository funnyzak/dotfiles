# CLAUDE.md - 开发指导

## 核心原则

1. **使用中文回复**：除非特别要求，始终使用中文交流
2. **任务完整性**：必须完成所有任务才能停止
3. **代码质量**：遵循 SOLID、DRY 原则，确保代码清晰可维护
4. **错误处理**：所有脚本必须包含适当的错误处理机制
5. **模块化设计**：优先创建可复用的模块化组件

## 开发规范

### 代码风格
- **缩进**：2 空格（遵循 .editorconfig）
- **行尾**：LF（Unix 风格）
- **编码**：UTF-8
- **文件结尾**：必须有换行符
- **空格**：删除尾随空格

### Shell 脚本 (.sh)
- 使用 `#!/bin/bash` 作为 shebang
- 函数命名：`snake_case`
- 环境变量：`UPPER_CASE`
- 关键脚本使用 `set -e`
- 复杂逻辑添加注释

### Zsh 配置 (.zsh)
- 模块化组织：别名、函数、插件分离
- 遵循 Oh My Zsh 约定
- 使用描述性命名
- **别名开发**：参考 [ZSHRC_ALIASES_GUIDE.md](docs/ZSHRC_ALIASES_GUIDE.md)

### Python 脚本 (.py)
- 遵循 PEP 8 规范
- 包含函数和类的文档字符串
- 使用虚拟环境（`.venv/`）

### 文档 (.md)
- 使用 GitHub Flavored Markdown
- 清晰的标题结构
- 提供使用示例

## 常用子代理选择

### 核心开发代理
- **通用开发**：`general-purpose` - 复杂问题研究和多步骤任务
- **代码审查**：`code-reviewer` - 代码质量、安全性、可维护性审查
- **文档更新**：`docs-updater` - 项目文档系统性更新
- **测试自动化**：`test-automator` - 测试套件和 CI/CD 集成

### 专业领域代理
- **Shell/脚本**：`python-pro`、`javascript-pro`
- **前端开发**：`frontend-developer` - React 19、Next.js 15
- **后端架构**：`backend-architect` - API 设计、微服务架构
- **云架构**：`cloud-architect` - AWS/Azure/GCP 基础设施
- **安全审计**：`security-auditor` - 漏洞评估、OWASP 合规性

### 质量保障代理
- **性能优化**：`performance-engineer` - 应用性能分析
- **调试专家**：`debugger` - 错误解决、问题诊断
- **架构审查**：`architect-review` - 架构一致性分析

## Shell 脚本开发规范

### 函数格式
```bash
#!/bin/bash
# 功能描述
function_name() {
    local var1="$1"
    local var2="$2"

    # 参数验证
    if [[ -z "$var1" ]]; then
        echo "错误：缺少必需参数" >&2
        return 1
    fi

    # 主要逻辑
    # ...
}
```

### 错误处理
- 使用 `set -e` 退出脚本
- 验证输入参数
- 提供有意义的错误信息
- 使用适当的退出码

### 跨平台兼容性
- 支持 macOS 和 Linux
- 避免平台特定的命令
- 测试不同环境下的兼容性

## 文档管理规范

### 基本原则
- **优先复用**：更新现有文档而非创建新文档
- **统一管理**：所有文档存储在统一文件夹中
- **模块化组织**：按模块组织，维护文档索引
- **简洁实用**：聚焦核心功能和使用方法
- **禁用表情符号**：保持专业性

### 文档组织
- 创建前搜索现有相关文档
- 按模块组织，保持清晰层级
- 维护文档索引便于导航
- 内容简洁实用，聚焦核心功能

### 脚本管理
- 可复用脚本：添加或更新脚本索引
- 不可复用脚本：删除该脚本
- 遵循模块化原则便于查找维护

## 项目特有要求

### dotfiles 项目特点
- 个人使用导向，注重实用性
- 多平台支持（macOS/Linux）
- Shell 为中心的配置管理
- 模块化组织结构

### 开发工作流程
- **测试**：`bash -n script.sh` 检查语法
- **Git**：主分支 `main`，使用约定式提交
- **文档**：功能变更后及时更新相关文档

### 质量保证
- 项目更新完成后，**必须**使用 `code-reviewer` 子代理进行审核
- 项目更新完成后，**必须**使用 `docs-updater` 子代理维护项目文档

## 快速参考

### 常用命令
```bash
# 测试 Shell 脚本
bash -n script.sh

# 安装 Oh My Zsh 配置
bash shells/oh-my-zsh/tools/install_omz.sh

# 安装别名
bash shells/oh-my-zsh/tools/install_omz_aliases.sh

# 运行 Python 工具
cd utilities/python && python script_name.py
```

### 添加新别名
1. 参考 [ZSHRC_ALIASES_GUIDE.md](docs/ZSHRC_ALIASES_GUIDE.md)
2. 在 `shells/oh-my-zsh/custom/aliases/` 创建文件
3. 使用函数格式：`alias name='() { ... }'`
4. 测试：`bash -n file.zsh` && `source ~/.zshrc`

### 详细指导索引
- **Zsh 别名开发**：[docs/ZSHRC_ALIASES_GUIDE.md](docs/ZSHRC_ALIASES_GUIDE.md)
- **项目文档**：[README.md](README.md)
- **Shell 配置**：[shells/](shells/)
- **实用工具**：[utilities/](utilities/)

---

**注意**：这是一个个人 dotfiles 仓库，修改时请考虑个人使用场景。所有脚本应具备防御性编程思维，远程安装脚本应包含多个 CDN 选项。
