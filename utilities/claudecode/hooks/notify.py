#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================
Claude Code Hook 通知脚本
============================================================

本脚本用于在 Claude Code 自动化流程或关键事件发生时，发送格式化的通知消息。
支持以下 Hook 事件类型：
  • UserPromptSubmit - 用户提交提示时
  • Stop - 主任务完成时  
  • SubagentStop - 子任务完成时
  • Notification - 系统通知时
  • SessionStart - 会话开始时
  • SessionEnd - 会话结束时
  • PreToolUse - 工具使用前
  • PostToolUse - 工具使用后
  • PreCompact - 对话压缩前

支持两种通知方式：
  1. apprise CLI (需要预先安装 apprise)
  2. apprise curl HTTP POST（地址通过环境变量配置）

【配置方法】
1. 通知方式选择：
    - 优先通过命令行参数 --notify-method 指定（apprise 或 curl）
    - 未指定时，读取环境变量 APPRISE_NOTIFY_METHOD
    - 默认使用 apprise

2. curl 方式配置：
    - 需设置环境变量 APPRISE_NOTIFY_URL 为目标 HTTP 地址
    - 例如：export APPRISE_NOTIFY_URL="https://your.notify.url/xxxx"

3. apprise 方式配置：
    - 需确保已安装 apprise CLI
    - 可通过 apprise 配置文件或环境变量自定义通知渠道

4. 来源信息配置（可选）：
    - CLAUDE_HOOK_SOURCE_NAME 或 APPRISE_SOURCE_NAME：设置自定义来源名称
    - 例如：export CLAUDE_HOOK_SOURCE_NAME="我的开发机"
    - 脚本会自动获取主机名和IP地址，无需额外配置

【使用方法】
1. 标准用法（apprise方式，自动读取环境变量）：
    $ cat event.json | python3 notify.py

2. 指定通知方式（curl）：
    $ export APPRISE_NOTIFY_URL="https://n.yycc.dev/notify/xxxx"
    $ cat event.json | python3 notify.py --notify-method curl

3. 指定 tag 标签：
    $ cat event.json | python3 notify.py --tag mytag

4. 结合环境变量与命令行参数：
    $ export APPRISE_NOTIFY_METHOD=curl
    $ export APPRISE_NOTIFY_URL="https://n.yycc.dev/notify/xxxx"
    $ cat event.json | python3 notify.py --tag urgent

5. 设置自定义来源名称：
    $ export CLAUDE_HOOK_SOURCE_NAME="Leon的MacBook Pro"
    $ cat event.json | python3 notify.py

【输入说明】
通过 stdin 传入 JSON 格式的事件数据，脚本会自动格式化为通知内容。

【示例事件数据】
{
  "hook_event_name": "UserPromptSubmit",
  "session_id": "abc123...",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/path/to/project",
  "prompt": "请帮我完成xxx"
}

{
  "hook_event_name": "Stop",
  "session_id": "abc123...",
  "transcript_path": "/path/to/transcript.jsonl",
  "stop_hook_active": false
}

【依赖要求】
- Python 3.6+
- apprise CLI（如需 apprise 通知）
- curl（如需 curl 通知）

【其他说明】
- 环境变量统一使用 APPRISE_ 前缀，避免与其他脚本冲突。
- 支持调试模式，设置 CLAUDE_HOOK_DEBUG 环境变量可输出原始事件数据。
- 来源信息自动获取：主机名、本地IP地址、系统类型。
- 支持通过 CLAUDE_HOOK_SOURCE_NAME 或 APPRISE_SOURCE_NAME 设置自定义来源名称。
- 如果无法获取某些来源信息，将自动跳过，不影响通知发送。
"""

import json
import sys
import os
import subprocess
import datetime
import argparse
import socket
import platform
from pathlib import Path

def format_duration(seconds):
    """格式化耗时显示"""
    if seconds is None:
        return "N/A"
    
    if seconds < 1:
        return f"{int(seconds * 1000)}ms"
    elif seconds < 60:
        return f"{seconds:.1f}s"
    elif seconds < 3600:
        minutes = int(seconds // 60)
        secs = int(seconds % 60)
        return f"{minutes}m{secs}s"
    else:
        hours = int(seconds // 3600)
        minutes = int((seconds % 3600) // 60)
        return f"{hours}h{minutes}m"

def truncate_text(text, max_length=100):
    """截断长文本并添加省略号"""
    if not text or len(text) <= max_length:
        return text
    return text[:max_length] + "..."

def get_project_name(cwd):
    """从工作目录获取项目名称"""
    if not cwd:
        return "Unknown Project"
    try:
        return Path(cwd).name
    except Exception:
        return "Unknown Project"

def get_source_info():
    """获取来源相关信息：主机名、来源IP、自定义名称"""
    source_info = {}
    
    # 获取主机名
    try:
        hostname = socket.gethostname()
        if hostname:
            source_info['hostname'] = hostname
    except Exception:
        pass
    
    # 获取来源IP（尝试连接外部地址获取本地IP）
    try:
        # 创建一个UDP socket连接到外部地址来获取本地IP
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            # 连接到Google DNS，不会实际发送数据
            s.connect(("8.8.8.8", 80))
            local_ip = s.getsockname()[0]
            if local_ip and local_ip != '127.0.0.1':
                source_info['source_ip'] = local_ip
    except Exception:
        # 如果上述方法失败，尝试获取hostname对应的IP
        try:
            local_ip = socket.gethostbyname(socket.gethostname())
            if local_ip and local_ip != '127.0.0.1':
                source_info['source_ip'] = local_ip
        except Exception:
            pass
    
    # 获取自定义名称（从环境变量）
    custom_name = os.getenv('CLAUDE_HOOK_SOURCE_NAME') or os.getenv('APPRISE_SOURCE_NAME')
    if custom_name:
        source_info['custom_name'] = custom_name
    
    # 获取系统信息作为补充
    try:
        system_info = platform.system()
        if system_info:
            source_info['system'] = system_info
    except Exception:
        pass
        
    return source_info

def format_notification_message(hook_data):
    """格式化通知消息"""
    event_name = hook_data.get('hook_event_name', 'Unknown')
    session_id = hook_data.get('session_id', 'N/A')
    transcript_path = hook_data.get('transcript_path', 'N/A')
    cwd = hook_data.get('cwd')  # 注意：某些事件(如Stop)没有cwd字段
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    source_info = get_source_info()
    
    # 基本信息
    title = f"🤖 Claude Code - {event_name}"
    
    # 如果有自定义名称，添加到标题中
    if 'custom_name' in source_info:
        title += f" [{source_info['custom_name']}]"
    
    content_lines = [
        f"📅 时间: {current_time}",
        f"🏷️ 会话ID: {session_id[:24]}...",
        f"🎯 事件类型: {event_name}"
    ]
    
    # 只有当cwd存在时才显示项目信息
    if cwd:
        project_name = get_project_name(cwd)
        content_lines.extend([
            f"📁 项目: {project_name}",
            f"📂 工作目录: {Path(cwd).name}"
        ])
    
    # 添加对话记录路径信息
    if transcript_path and transcript_path != 'N/A':
        content_lines.append(f"📜 对话记录: {Path(transcript_path).name}")
    
    # 添加来源信息（如果可用）
    source_lines = []
    if 'hostname' in source_info:
        source_lines.append(f"🖥️ 主机名: {source_info['hostname']}")
    if 'source_ip' in source_info:
        source_lines.append(f"🌐 来源IP: {source_info['source_ip']}")
    if 'system' in source_info:
        source_lines.append(f"💻 系统: {source_info['system']}")
    
    if source_lines:
        content_lines.extend(source_lines)
    
    content_lines.append("")
    
    # 根据事件类型添加特定信息
    if event_name == "UserPromptSubmit":
        # 用户提交prompt事件
        prompt = hook_data.get('prompt', 'No prompt')
        content_lines.extend([
            "🤔 状态: 用户提交新提示",
            f"📝 输入: {truncate_text(prompt, 200)}",
            "📋 描述: 用户已提交新的对话内容"
        ])
        
    elif event_name == "Stop":
        # 主任务完成事件
        stop_hook_active = hook_data.get('stop_hook_active', False)
        content_lines.extend([
            "✅ 状态: 主任务执行完成",
            f"🔄 Hook循环: {'是' if stop_hook_active else '否'}",
            "📋 描述: Claude已完成当前任务的处理"
        ])
        
        if stop_hook_active:
            content_lines.append("⚠️ 注意: 当前处于stop hook循环中")
            
    elif event_name == "SubagentStop":
        # 子任务完成事件
        stop_hook_active = hook_data.get('stop_hook_active', False)
        content_lines.extend([
            "✅ 状态: 子任务执行完成",
            f"🔄 Hook循环: {'是' if stop_hook_active else '否'}",
            "📋 描述: 子代理已完成指定任务"
        ])
        
        if stop_hook_active:
            content_lines.append("⚠️ 注意: 当前处于stop hook循环中")
            
    elif event_name == "Notification":
        # 通知事件
        message = hook_data.get('message', 'No message')
        content_lines.extend([
            "⚠️ 状态: 系统通知",
            f"💬 消息: {truncate_text(message, 150)}",
            "📋 描述: Claude Code发送了通知消息"
        ])
        
    elif event_name == "SessionStart":
        # 会话开始事件 - 注意字段名是source而不是matcher
        source = hook_data.get('source', 'unknown')
        content_lines.extend([
            "🚀 状态: 新会话开始",
            f"🎪 启动来源: {source}",
            "📋 描述: Claude Code会话已启动"
        ])
        
        # 根据不同的启动来源提供更详细的说明
        source_descriptions = {
            'startup': '应用程序启动',
            'resume': '恢复会话 (--resume/--continue/resume)',
            'clear': '清除会话 (/clear)',
            'compact': '压缩操作后重启'
        }
        if source in source_descriptions:
            content_lines.append(f"ℹ️ 说明: {source_descriptions[source]}")
        
    elif event_name == "SessionEnd":
        # 会话结束事件
        reason = hook_data.get('reason', 'unknown')
        content_lines.extend([
            "🛑 状态: 会话已结束",
            f"🎭 结束原因: {reason}",
            "📋 描述: Claude Code会话已终止"
        ])
        
        # 根据不同的结束原因提供更详细的说明
        reason_descriptions = {
            'clear': '用户执行了 /clear 命令',
            'logout': '用户登出',
            'prompt_input_exit': '用户在提示输入时退出',
            'other': '其他原因导致的退出'
        }
        if reason in reason_descriptions:
            content_lines.append(f"ℹ️ 说明: {reason_descriptions[reason]}")
    
    elif event_name == "PreToolUse":
        # 工具使用前事件
        tool_name = hook_data.get('tool_name', 'Unknown')
        tool_input = hook_data.get('tool_input', {})
        content_lines.extend([
            "🔧 状态: 准备使用工具",
            f"�️ 工具名称: {tool_name}",
            "📋 描述: Claude准备执行工具调用"
        ])
        
        # 显示工具输入的关键信息
        if tool_input:
            key_info = []
            if 'file_path' in tool_input:
                key_info.append(f"文件: {Path(tool_input['file_path']).name}")
            if 'command' in tool_input:
                key_info.append(f"命令: {truncate_text(tool_input['command'], 60)}")
            if key_info:
                content_lines.append(f"📄 参数: {', '.join(key_info)}")
    
    elif event_name == "PostToolUse":
        # 工具使用后事件
        tool_name = hook_data.get('tool_name', 'Unknown')
        tool_response = hook_data.get('tool_response', {})
        content_lines.extend([
            "✅ 状态: 工具执行完成",
            f"🛠️ 工具名称: {tool_name}",
            "📋 描述: Claude已完成工具调用"
        ])
        
        # 显示执行结果
        if tool_response:
            success = tool_response.get('success', 'unknown')
            content_lines.append(f"🎯 执行结果: {'成功' if success else '失败' if success is False else '未知'}")
    
    elif event_name == "PreCompact":
        # 压缩前事件
        trigger = hook_data.get('trigger', 'unknown')
        custom_instructions = hook_data.get('custom_instructions', '')
        content_lines.extend([
            "� 状态: 准备压缩对话",
            f"� 触发方式: {trigger}",
            "📋 描述: Claude准备压缩对话历史"
        ])
        
        if custom_instructions:
            content_lines.append(f"📝 自定义指令: {truncate_text(custom_instructions, 100)}")
    
    # 添加额外的调试信息（可选）
    if os.getenv('CLAUDE_HOOK_DEBUG'):
        content_lines.extend([
            "",
            "🔧 调试信息:",
            f"原始事件数据: {json.dumps(hook_data, ensure_ascii=False, indent=2)[:300]}..."
        ])
    
    content = "\n".join(content_lines)
    return title, content

def send_notification(title, content, tag='claudecode'):
    """根据 method 参数或环境变量选择发送方式: apprise 或 curl"""
    method = getattr(send_notification, '_method', None)
    if not method:
        method = os.getenv('APPRISE_NOTIFY_METHOD', 'apprise').lower()
    else:
        method = method.lower()
    if method == 'curl':
        notify_url = os.getenv('APPRISE_NOTIFY_URL')
        if not notify_url:
            print("❌ APPRISE_NOTIFY_URL 环境变量未设置", file=sys.stderr)
            return False
        try:
            cmd = [
                'curl', '-X', 'POST',
                '-F', f'title={title}',
                '-F', f'body={content}',
                '-F', f'tags={tag}',
                notify_url
            ]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            if result.returncode == 0:
                print(f"✅ curl通知发送成功: {title}", file=sys.stderr)
            else:
                print(f"❌ curl通知发送失败: {result.stderr}", file=sys.stderr)
                return False
        except FileNotFoundError:
            print("❌ curl命令未找到", file=sys.stderr)
            return False
        except Exception as e:
            print(f"❌ curl发送通知时出错: {str(e)}", file=sys.stderr)
            return False
        return True
    else:
        try:
            cmd = [
                'apprise',
                '-t', title,
                '-b', content,
                f'--tag={tag}',
                '-vv'
            ]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                encoding='utf-8'
            )
            if result.returncode == 0:
                print(f"✅ apprise通知发送成功: {title}", file=sys.stderr)
            else:
                print(f"❌ apprise通知发送失败: {result.stderr}", file=sys.stderr)
                return False
        except FileNotFoundError:
            print("❌ apprise命令未找到，请确保已安装apprise", file=sys.stderr)
            return False
        except Exception as e:
            print(f"❌ apprise发送通知时出错: {str(e)}", file=sys.stderr)
            return False
        return True

def main():
    """主函数"""
    # 解析命令行参数
    parser = argparse.ArgumentParser(
        description='Claude Code Hook通知脚本',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--tag', '-t',
        default='claudecode',
        help='发送通知时使用的tag标签 (默认: claudecode)'
    )
    parser.add_argument(
        '--notify-method',
        choices=['apprise', 'curl'],
        help='通知发送方式，可选 apprise 或 curl，优先于环境变量'
    )

    args = parser.parse_args()

    try:
        # 从stdin读取JSON数据
        input_data = json.load(sys.stdin)

        # 格式化消息
        title, content = format_notification_message(input_data)

        # 优先使用命令行参数，其次环境变量
        if args.notify_method:
            send_notification._method = args.notify_method
        else:
            send_notification._method = None

        # 发送通知
        success = send_notification(title, content, tag=args.tag)

        # 输出状态到stderr供调试
        if success:
            print("Hook执行成功", file=sys.stderr)
        else:
            print("Hook执行失败", file=sys.stderr)
            sys.exit(1)

    except json.JSONDecodeError as e:
        print(f"❌ JSON解析错误: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"❌ Hook执行错误: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
