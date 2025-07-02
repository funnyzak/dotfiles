#!/bin/bash
# SSH Port Forward - 最大连接保持时间配置
# 此配置专为长时间保持SSH连接而优化

echo "正在设置最大连接保持时间配置..."

# =========================================================================
# 核心超时设置 - 最大化连接保持时间
# =========================================================================

# Expect 超时设置 (非常长，防止expect脚本超时)
export SSH_TIMEOUT=3600                    # 1小时，防止expect脚本超时
export SSH_CONNECTION_TIMEOUT=120          # SSH连接超时 (2分钟)

# 重试设置
export SSH_MAX_ATTEMPTS=3                  # 重试次数 (避免过多重试)

# =========================================================================
# 保活设置 - 关键配置，保持连接活跃
# =========================================================================

# 启用所有保活机制
export SSH_KEEP_ALIVE=1                    # 启用保活
export SSH_TCP_KEEP_ALIVE=1                # 启用TCP保活

# 保活间隔设置 (平衡网络负载和连接保持)
export SSH_ALIVE_INTERVAL=30               # 保活间隔 (30秒)
export SSH_ALIVE_COUNT=20                  # 保活计数 (20次 = 10分钟容错)

# 空闲超时设置 (禁用空闲超时)
export SSH_IDLE_TIMEOUT=0                  # 0 = 禁用空闲超时

# =========================================================================
# 其他优化设置
# =========================================================================

# 输出设置
export SSH_NO_COLOR=0                      # 启用彩色输出

# 配置文件路径
export PORT_FORWARD_CONFIG="$HOME/.ssh/port_forward.conf"

echo "配置完成！"
echo ""
echo "当前配置:"
echo "  SSH_TIMEOUT: $SSH_TIMEOUT 秒"
echo "  SSH_CONNECTION_TIMEOUT: $SSH_CONNECTION_TIMEOUT 秒"
echo "  SSH_ALIVE_INTERVAL: $SSH_ALIVE_INTERVAL 秒"
echo "  SSH_ALIVE_COUNT: $SSH_ALIVE_COUNT"
echo "  SSH_IDLE_TIMEOUT: $SSH_IDLE_TIMEOUT (禁用)"
echo "  SSH_MAX_ATTEMPTS: $SSH_MAX_ATTEMPTS"
echo ""
echo "使用说明:"
echo "  source ./max_connection_timeout.sh"
echo "  ./ssh_port_forward.exp [server_id]"
echo ""
echo "此配置将:"
echo "  ✓ 保持连接最长可达数天"
echo "  ✓ 每30秒发送保活信号"
echo "  ✓ 允许20次保活失败 (10分钟容错)"
echo "  ✓ 禁用空闲超时"
echo "  ✓ 优化网络稳定性"
