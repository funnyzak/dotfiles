#!/usr/bin/env bash

#############################################################
# 命令行速查表工具 (cheatsheet.sh)
#
# 描述:
#   这是一个用户友好的、跨平台的Shell命令行速查表工具脚本，
#   帮助开发者快速查询常用命令行的速查手册，提高工作效率。
#   脚本支持命令行参数模式和交互式菜单模式，支持本地缓存。
#
# 作者: GitHub Copilot
# 版本: 1.0.0
# 日期: 2025-03-26
# 许可: MIT License
# 仓库: https://github.com/funnyzak/dotfiles
#
# 详细使用示例:
#
# 1. 本地使用示例:
#    基本用法:
#      ./cheatsheet.sh                  # 启动交互式菜单模式
#      ./cheatsheet.sh git              # 直接查看git命令速查表
#      ./cheatsheet.sh -l               # 列出所有可用命令
#      ./cheatsheet.sh -h               # 显示帮助信息
#
#    高级选项:
#      ./cheatsheet.sh -c git           # 使用中国区域加速URL查看git命令
#      ./cheatsheet.sh -g docker        # 使用GitHub源URL查看docker命令
#      ./cheatsheet.sh -u https://example.com/commands/ git  # 使用自定义URL
#
# 2. 远程执行示例:
#    使用curl直接远程执行:
#      bash -c "$(curl -fsSL https://github.com/funnyzak/dotfiles/raw/docs/utilities/shell/cheatsheet.sh)" -- git
#
#    或使用wget:
#      bash -c "$(wget -qO- https://github.com/funnyzak/dotfiles/raw/docs/utilities/shell/cheatsheet.sh)" -- docker
#
#    带参数远程执行:
#      bash -c "$(curl -fsSL https://github.com/funnyzak/dotfiles/raw/docs/utilities/shell/cheatsheet.sh)" -- -c nginx
#
# 3. 安装到本地:
#    下载并安装到/usr/local/bin:
#      curl -fsSL https://github.com/funnyzak/dotfiles/raw/docs/utilities/shell/cheatsheet.sh -o /usr/local/bin/cheatsheet && chmod +x /usr/local/bin/cheatsheet
#
#    然后就可以在任何地方使用cheatsheet命令:
#      cheatsheet git
#      cheatsheet -c docker
#
# 4. 使用别名简化:
#    在~/.bashrc或~/.zshrc中添加:
#      alias cs='bash /path/to/cheatsheet.sh'
#
#    然后可以使用简短命令:
#      cs git
#      cs -l
#
# 5. 在Docker中使用:
#    docker run --rm -it bash -c "$(curl -fsSL https://github.com/funnyzak/dotfiles/raw/docs/utilities/shell/cheatsheet.sh)" -- nginx
#
#############################################################

# 设置严格模式，提高脚本健壮性
set -euo pipefail

# 定义颜色变量，用于美化输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # 无颜色

# 速查表数据源URL前缀
DEFAULT_URL="https://github.com/funnyzak/dotfiles/raw/refs/heads/main/docs/command/"
CHINA_URL="https://raw.gitcode.com/funnyzak/dotfiles/raw/docs/docs/command/"
CURRENT_URL=$DEFAULT_URL
TIMEOUT=5 # 超时时间(秒)

# 定义命令列表和描述
# 格式: "命令名称:分类目录:描述"
COMMANDS=(
    "adb:android:Android Debug Bridge工具，用于管理Android设备"
    "ffmpeg:media:音视频处理工具，用于转换、编辑、录制等"
    "imagemagick:media:图像处理工具，支持图像编辑、转换和生成"
    "curl:network:命令行网络工具，用于传输数据"
    "netstat:network:网络统计工具，显示网络连接、路由表等"
    "nmcli:network:NetworkManager命令行工具，用于管理网络连接"
    "tcpdump:network:网络数据包分析工具"
    "wget:network:命令行下载工具"
    "npm:package:Node.js包管理器"
    "pnpm:package:快速、节省磁盘空间的包管理器"
    "yarn:package:替代npm的JavaScript包管理器"
    "golang:runtime:Go语言运行时命令"
    "java:runtime:Java运行时命令"
    "node:runtime:Node.js运行时命令"
    "python:runtime:Python运行时命令"
    "apt:system:Debian/Ubuntu系统包管理工具"
    "awk:system:强大的文本处理语言"
    "cat:system:连接文件并输出到标准输出"
    "chmod:system:更改文件权限"
    "chown:system:更改文件所有者和组"
    "df:system:报告文件系统磁盘空间使用情况"
    "du:system:估算文件空间使用量"
    "grep:system:文本搜索工具"
    "ip:system:显示/操作路由、设备、策略路由等"
    "iptables:system:Linux防火墙管理工具"
    "less:system:文件内容查看器"
    "mount:system:挂载文件系统"
    "nano:system:简单易用的文本编辑器"
    "operators:system:Shell操作符参考"
    "rclone:system:云存储同步工具"
    "rsync:system:高效文件同步工具"
    "systemctl:system:systemd服务管理工具"
    "vim:system:高级文本编辑器"
    "watch:system:定期执行命令"
    "yum:system:CentOS/RHEL包管理工具"
    "docker:tools:容器化平台管理工具"
    "git:tools:分布式版本控制系统"
    "caddy:webserver:轻量级现代Web服务器"
    "nginx:webserver:高性能Web服务器和反向代理"
)

# 函数: 显示帮助信息
show_help() {
    echo -e "${BOLD}命令行速查表工具${NC} - 快速查询各种命令的速查手册"
    echo
    echo -e "${BOLD}用法:${NC}"
    echo "  $(basename "$0") [选项] [命令名称]"
    echo
    echo -e "${BOLD}选项:${NC}"
    echo "  -h, --help      显示此帮助信息"
    echo "  -l, --list      列出所有可用的命令"
    echo "  -u, --url URL   自定义速查表数据源URL前缀"
    echo "  -c, --china     使用中国区域加速URL"
    echo "  -g, --github    使用GitHub源URL(默认)"
    echo
    echo -e "${BOLD}示例:${NC}"
    echo "  $(basename "$0")            # 启动交互式菜单模式"
    echo "  $(basename "$0") git        # 显示git命令的速查表"
    echo "  $(basename "$0") -l         # 列出所有可用的命令"
    echo "  $(basename "$0") -c git     # 使用中国区域加速URL显示git速查表"
    echo
    echo -e "${BOLD}注意:${NC}"
    echo "  交互式菜单模式中，输入q或quit可以退出程序"
}

# 函数: 检查URL可访问性并选择最佳URL
check_url_accessibility() {
    local url_to_check=$1
    # 使用curl的静默模式，只检查连接性
    if curl --connect-timeout $TIMEOUT -s --head --fail "$url_to_check" > /dev/null 2>&1; then
        return 0 # URL可访问
    else
        return 1 # URL不可访问
    fi
}

# 函数: 自动选择最佳URL
auto_select_best_url() {
    echo -e "${BLUE}正在检测最佳数据源...${NC}"

    # 先尝试中国区域加速URL
    if check_url_accessibility "${CHINA_URL}system/cat-cheatsheet.txt"; then
        CURRENT_URL=$CHINA_URL
        echo -e "${GREEN}已自动选择中国区域加速URL${NC}"
    # 然后尝试默认GitHub URL
    elif check_url_accessibility "${DEFAULT_URL}system/cat-cheatsheet.txt"; then
        CURRENT_URL=$DEFAULT_URL
        echo -e "${GREEN}已自动选择GitHub源URL${NC}"
    else
        echo -e "${YELLOW}警告: 所有数据源似乎都无法访问，将使用默认URL${NC}"
        CURRENT_URL=$DEFAULT_URL
    fi
}

# 函数: 列出所有可用的命令
list_commands() {
    echo -e "${BOLD}可用的命令列表:${NC}"
    echo

    # 按分类分组显示命令
    local categories=()
    local category=""

    # 提取所有唯一的分类
    for cmd_info in "${COMMANDS[@]}"; do
        local cmd_category=$(echo "$cmd_info" | cut -d':' -f2)
        if [[ ! " ${categories[@]} " =~ " ${cmd_category} " ]]; then
            categories+=("$cmd_category")
        fi
    done

    # 对分类进行排序
    IFS=$'\n' sorted_categories=($(sort <<<"${categories[*]}"))
    unset IFS

    # 按分类显示命令
    for category in "${sorted_categories[@]}"; do
        echo -e "${BOLD}${PURPLE}${category^}:${NC}"  # 首字母大写的分类名

        # 遍历命令列表，显示该分类下的命令
        for cmd_info in "${COMMANDS[@]}"; do
            IFS=':' read -r cmd_name cmd_category cmd_desc <<< "$cmd_info"
            if [[ "$cmd_category" == "$category" ]]; then
                echo -e "  ${GREEN}${cmd_name}${NC} - ${cmd_desc}"
            fi
        done
        echo
    done
}

# 函数: 显示交互式菜单
show_interactive_menu() {
    clear
    echo -e "${BOLD}${BLUE}命令行速查表工具 - 交互式菜单${NC}"
    echo -e "${YELLOW}当前数据源: ${CURRENT_URL}${NC}"
    echo -e "${CYAN}请选择要查看的命令 (输入编号, 或输入q/quit退出):${NC}"
    echo

    local i=1
    local last_category=""
    local categories=()
    local commands_by_category=()

    # 提取所有唯一的分类
    for cmd_info in "${COMMANDS[@]}"; do
        local cmd_category=$(echo "$cmd_info" | cut -d':' -f2)
        if [[ ! " ${categories[@]} " =~ " ${cmd_category} " ]]; then
            categories+=("$cmd_category")
        fi
    done

    # 对分类进行排序
    IFS=$'\n' sorted_categories=($(sort <<<"${categories[*]}"))
    unset IFS

    # 按分类显示命令
    for category in "${sorted_categories[@]}"; do
        echo -e "${BOLD}${PURPLE}${category^}:${NC}"  # 首字母大写的分类名

        # 遍历命令列表，显示该分类下的命令
        for cmd_info in "${COMMANDS[@]}"; do
            IFS=':' read -r cmd_name cmd_category cmd_desc <<< "$cmd_info"
            if [[ "$cmd_category" == "$category" ]]; then
                printf "  ${BOLD}%2d${NC}) ${GREEN}%-15s${NC} - %s\n" $i "$cmd_name" "$cmd_desc"
                commands_by_index[$i]=$cmd_name
                ((i++))
            fi
        done
        echo
    done

    echo -e "${BOLD}${CYAN}请输入编号或命令名称 (1-$((i-1)), q退出): ${NC}"
    read -r choice

    # 处理用户选择
    if [[ "$choice" == "q" || "$choice" == "quit" ]]; then
        echo -e "${YELLOW}退出程序${NC}"
        exit 0
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
        # 用户输入了有效的编号
        local selected_cmd="${commands_by_index[$choice]}"
        show_cheatsheet "$selected_cmd"

        # 显示完成后提示继续
        echo -e "${CYAN}按Enter键继续...${NC}"
        read -r
        show_interactive_menu # 重新显示菜单
    elif [[ "$choice" =~ ^[a-zA-Z]+$ ]]; then
        # 用户输入了命令名称，尝试查找匹配
        local found=0
        for cmd_info in "${COMMANDS[@]}"; do
            local cmd_name=$(echo "$cmd_info" | cut -d':' -f1)
            if [[ "$cmd_name" == "$choice" ]]; then
                show_cheatsheet "$cmd_name"
                found=1
                break
            fi
        done

        if [[ $found -eq 0 ]]; then
            echo -e "${RED}错误: 未找到命令 '$choice'${NC}"
            sleep 2
        else
            # 显示完成后提示继续
            echo -e "${CYAN}按Enter键继续...${NC}"
            read -r
        fi

        show_interactive_menu # 重新显示菜单
    else
        echo -e "${RED}无效的选择，请重试${NC}"
        sleep 2
        show_interactive_menu # 重新显示菜单
    fi
}

# 函数: 显示命令的速查表
show_cheatsheet() {
    local cmd_name="$1"
    local cmd_category=""
    local cmd_desc=""
    local found=0

    # 查找命令及其分类
    for cmd_info in "${COMMANDS[@]}"; do
        IFS=':' read -r name category desc <<< "$cmd_info"
        if [[ "$name" == "$cmd_name" ]]; then
            cmd_category=$category
            cmd_desc=$desc
            found=1
            break
        fi
    done

    if [[ $found -eq 0 ]]; then
        echo -e "${RED}错误: 未找到命令 '$cmd_name'${NC}"
        echo -e "${YELLOW}提示: 使用 '$(basename "$0") -l' 查看所有可用的命令${NC}"
        exit 1
    fi

    # 构建URL
    local url="${CURRENT_URL}${cmd_category}/${cmd_name}-cheatsheet.txt"

    echo -e "${BLUE}正在获取 ${GREEN}${cmd_name}${BLUE} 的速查表...${NC}"

    # 创建临时目录用于缓存
    local cache_dir="/tmp/cheatsheet-cache"
    mkdir -p "$cache_dir"
    local cache_file="${cache_dir}/${cmd_name}-cheatsheet.txt"

    # 检查缓存是否存在且不超过24小时(86400秒)
    if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file"))) -lt 86400 ]]; then
        echo -e "${GREEN}从缓存加载速查表...${NC}"
        less -R "$cache_file" || cat "$cache_file" | more
    else
        echo -e "${YELLOW}从远程获取速查表...${NC}"
        # 使用curl下载速查表
        if curl -s --connect-timeout $TIMEOUT "$url" -o "$cache_file"; then
            if [[ -s "$cache_file" ]]; then
                less -R "$cache_file" || cat "$cache_file" | more
            else
                echo -e "${RED}错误: 获取到的速查表为空${NC}"
                rm -f "$cache_file"  # 删除空文件
                exit 1
            fi
        else
            echo -e "${RED}错误: 无法获取速查表，请检查网络连接或URL${NC}"
            echo -e "${YELLOW}尝试的URL: ${url}${NC}"
            exit 1
        fi
    fi
}

# 主函数
main() {
    # 声明关联数组用于交互式菜单
    if [[ "${BASH_VERSINFO[0]}" -ge 4 ]]; then
        declare -A commands_by_index
    else
        echo -e "${YELLOW}警告: 关联数组不支持，交互式菜单可能无法正常工作。请使用Bash 4.0或更高版本。\n${NC}"
    fi

    # 解析命令行参数
    if [[ $# -eq 0 ]]; then
        # 无参数，进入交互式菜单模式
        auto_select_best_url
        show_interactive_menu
    else
        # 解析参数
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    show_help
                    exit 0
                    ;;
                -l|--list)
                    list_commands
                    exit 0
                    ;;
                -u|--url)
                    if [[ -n "$2" ]]; then
                        CURRENT_URL="$2"
                        shift 2
                    else
                        echo -e "${RED}错误: --url 选项需要一个参数${NC}"
                        exit 1
                    fi
                    ;;
                -c|--china)
                    CURRENT_URL=$CHINA_URL
                    shift
                    ;;
                -g|--github)
                    CURRENT_URL=$DEFAULT_URL
                    shift
                    ;;
                -*)
                    echo -e "${RED}错误: 未知选项 $1${NC}"
                    echo -e "${YELLOW}使用 '$(basename "$0") --help' 获取帮助信息${NC}"
                    exit 1
                    ;;
                *)
                    # 假定是命令名称
                    show_cheatsheet "$1"
                    exit 0
                    ;;
            esac
        done
    fi
}

# 执行主函数
main "$@"
