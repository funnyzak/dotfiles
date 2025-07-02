# SSH 连接保持时间优化指南

## 概述

本指南提供不同场景下SSH连接的最大保持时间配置，确保端口转发连接能够长时间稳定运行。

## 🏆 最佳配置 (推荐)

### 标准长时间保持配置
```bash
# 加载最佳配置
source ./max_connection_timeout.sh

# 运行端口转发
./ssh_port_forward.exp [server_id]
```

**配置特点:**
- 连接保持时间：**数天到数周**
- 保活间隔：30秒
- 容错时间：10分钟
- 禁用空闲超时

## 📊 不同场景的配置

### 1. 极长时间保持 (数周/数月)
```bash
export SSH_TIMEOUT=86400                   # 24小时
export SSH_CONNECTION_TIMEOUT=300          # 5分钟
export SSH_ALIVE_INTERVAL=60               # 1分钟保活
export SSH_ALIVE_COUNT=30                  # 30次容错 (30分钟)
export SSH_IDLE_TIMEOUT=0                  # 禁用空闲超时
export SSH_MAX_ATTEMPTS=3
```

**适用场景:** 长期稳定的网络环境，需要连接保持数周或数月

### 2. 平衡配置 (推荐)
```bash
export SSH_TIMEOUT=3600                    # 1小时
export SSH_CONNECTION_TIMEOUT=120          # 2分钟
export SSH_ALIVE_INTERVAL=30               # 30秒保活
export SSH_ALIVE_COUNT=20                  # 20次容错 (10分钟)
export SSH_IDLE_TIMEOUT=0                  # 禁用空闲超时
export SSH_MAX_ATTEMPTS=3
```

**适用场景:** 大多数网络环境，平衡稳定性和网络负载

### 3. 高频率保活 (不稳定网络)
```bash
export SSH_TIMEOUT=1800                    # 30分钟
export SSH_CONNECTION_TIMEOUT=60           # 1分钟
export SSH_ALIVE_INTERVAL=15               # 15秒保活
export SSH_ALIVE_COUNT=40                  # 40次容错 (10分钟)
export SSH_IDLE_TIMEOUT=0                  # 禁用空闲超时
export SSH_MAX_ATTEMPTS=5
```

**适用场景:** 网络不稳定，需要更频繁的保活信号

### 4. 低频率保活 (稳定网络)
```bash
export SSH_TIMEOUT=7200                    # 2小时
export SSH_CONNECTION_TIMEOUT=180          # 3分钟
export SSH_ALIVE_INTERVAL=120              # 2分钟保活
export SSH_ALIVE_COUNT=15                  # 15次容错 (30分钟)
export SSH_IDLE_TIMEOUT=0                  # 禁用空闲超时
export SSH_MAX_ATTEMPTS=3
```

**适用场景:** 非常稳定的网络环境，减少网络负载

## 🔧 高级配置选项

### 服务器端配置 (需要管理员权限)

在服务器端的 `/etc/ssh/sshd_config` 中添加：

```bash
# 客户端保活设置
ClientAliveInterval 30
ClientAliveCountMax 20

# TCP保活设置
TCPKeepAlive yes

# 禁用空闲超时
ClientAliveInterval 0
```

### 客户端SSH配置

在 `~/.ssh/config` 中添加：

```bash
Host *
    ServerAliveInterval 30
    ServerAliveCountMax 20
    TCPKeepAlive yes
    Compression yes
    CompressionLevel 6
```

## 📈 性能优化建议

### 1. 网络层面
- 使用有线连接而非WiFi
- 避免网络地址转换(NAT)层数过多
- 确保防火墙允许SSH连接

### 2. 系统层面
```bash
# 调整TCP保活参数 (Linux)
echo 300 > /proc/sys/net/ipv4/tcp_keepalive_time
echo 30 > /proc/sys/net/ipv4/tcp_keepalive_intvl
echo 5 > /proc/sys/net/ipv4/tcp_keepalive_probes

# macOS 调整
sudo sysctl -w net.inet.tcp.keepidle=300
sudo sysctl -w net.inet.tcp.keepintvl=30
sudo sysctl -w net.inet.tcp.keepcnt=5
```

### 3. 监控连接状态
```bash
# 监控SSH连接
watch -n 5 "netstat -an | grep :22"

# 检查保活状态
ss -o state established '( sport = :22 )'
```

## 🚨 故障排除

### 连接频繁断开
1. **检查网络稳定性**
   ```bash
   ping -c 100 <server_ip>
   ```

2. **增加保活频率**
   ```bash
   export SSH_ALIVE_INTERVAL=15
   export SSH_ALIVE_COUNT=40
   ```

3. **检查服务器配置**
   ```bash
   ssh -v <user>@<host> -o ServerAliveInterval=30
   ```

### 连接超时
1. **增加超时时间**
   ```bash
   export SSH_TIMEOUT=7200
   export SSH_CONNECTION_TIMEOUT=300
   ```

2. **检查防火墙设置**
   ```bash
   telnet <server_ip> <ssh_port>
   ```

### 端口转发失败
1. **检查端口占用**
   ```bash
   netstat -tulpn | grep :<local_port>
   ```

2. **验证远程端口**
   ```bash
   ssh <user>@<host> "netstat -tulpn | grep :<remote_port>"
   ```

## 📋 配置检查清单

- [ ] 设置了合适的 `SSH_ALIVE_INTERVAL`
- [ ] 配置了足够的 `SSH_ALIVE_COUNT`
- [ ] 禁用了 `SSH_IDLE_TIMEOUT`
- [ ] 启用了 `SSH_TCP_KEEP_ALIVE`
- [ ] 服务器端配置了相应的保活参数
- [ ] 网络环境稳定
- [ ] 防火墙允许SSH连接

## 🎯 推荐使用流程

1. **首次使用**: 使用标准配置
   ```bash
   source ./max_connection_timeout.sh
   ./ssh_port_forward.exp
   ```

2. **根据网络环境调整**:
   - 稳定网络 → 降低保活频率
   - 不稳定网络 → 提高保活频率

3. **监控连接状态**:
   - 定期检查连接是否正常
   - 记录断开频率和原因

4. **优化配置**:
   - 根据实际使用情况微调参数
   - 平衡稳定性和网络负载

## 📞 技术支持

如果遇到连接问题，请检查：
1. 网络连接状态
2. 服务器SSH服务状态
3. 防火墙配置
4. 配置文件语法
5. 权限设置
