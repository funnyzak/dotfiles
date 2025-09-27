#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
============================================================
Claude Code Hook 通知脚本
============================================================

本脚本用于在 Claude Code 自动化流程或关键事件发生时，发送格式化的通知消息。
支持两种通知方式：
  1. apprise CLI
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

【输入说明】
通过 stdin 传入 JSON 格式的事件数据，脚本会自动格式化为通知内容。

【示例事件数据】
{
  "hook_event_name": "Stop",
  "session_id": "abc123...",
  "cwd": "/path/to/project",
  "last_user_message": "请帮我完成xxx"
}

【依赖要求】
- Python 3.6+
- apprise CLI（如需 apprise 通知）
- curl（如需 curl 通知）

【其他说明】
- 环境变量统一使用 APPRISE_ 前缀，避免与其他脚本冲突。
- 支持调试模式，设置 CLAUDE_HOOK_DEBUG 环境变量可输出原始事件数据。
"""

import json
import sys
import os
import subprocess
import datetime
import argparse
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
    return Path(cwd).name

def format_notification_message(hook_data):
    """格式化通知消息"""
    event_name = hook_data.get('hook_event_name', 'Unknown')
    session_id = hook_data.get('session_id', 'N/A')
    cwd = hook_data.get('cwd', 'N/A')
    current_time = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    project_name = get_project_name(cwd)

    # 基本信息
    title = f"🤖 Claude Code - {event_name}"

    content_lines = [
        f"📅 时间: {current_time}",
        f"🏷️ 会话ID: {session_id[:24]}...",
        f"📁 项目: {project_name}",
        f"📂 工作目录: {Path(cwd).name}",
        f"🎯 事件类型: {event_name}",
        ""
    ]

    # 根据事件类型添加特定信息
    if event_name == "Stop":
        # 主任务完成事件
        content_lines.extend([
            "✅ 状态: 主任务执行完成",
            "📋 描述: Claude已完成当前任务的处理"
        ])

        # 尝试获取最后的用户prompt（如果有的话）
        if 'last_user_message' in hook_data:
            prompt = truncate_text(hook_data['last_user_message'], 80)
            content_lines.append(f"💬 最后提示: {prompt}")

    elif event_name == "SubagentStop":
        # 子任务完成事件
        content_lines.extend([
            "✅ 状态: 子任务执行完成",
            "📋 描述: 子代理已完成指定任务"
        ])

        if 'task_info' in hook_data:
            task_info = truncate_text(str(hook_data['task_info']), 80)
            content_lines.append(f"🎯 任务: {task_info}")

    elif event_name == "Notification":
        # 需要确认的通知事件
        notification_type = hook_data.get('notification_type', 'unknown')
        message = hook_data.get('message', 'No message')

        content_lines.extend([
            "⚠️ 状态: 需要用户确认",
            f"📋 类型: {notification_type}",
            f"💬 消息: {truncate_text(message, 100)}"
        ])

    elif event_name == "SessionStart":
        # 会话开始事件
        start_reason = hook_data.get('matcher', 'startup')
        content_lines.extend([
            "🚀 状态: 新会话开始",
            f"🎪 启动原因: {start_reason}",
            "📋 描述: Claude Code会话已启动"
        ])

    elif event_name == "SessionEnd":
        # 会话结束事件
        end_reason = hook_data.get('reason', 'unknown')
        content_lines.extend([
            "🛑 状态: 会话已结束",
            f"🎭 结束原因: {end_reason}",
            "📋 描述: Claude Code会话已终止"
        ])

    # 添加额外的调试信息（可选）
    if os.getenv('CLAUDE_HOOK_DEBUG'):
        content_lines.extend([
            "",
            "🔧 调试信息:",
            f"Raw event data: {json.dumps(hook_data, ensure_ascii=False, indent=2)[:200]}..."
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
