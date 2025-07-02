# SSH Port Forward Tool

一个基于 Expect 的 SSH 端口转发工具，支持多服务器配置和自动重连。

## 功能特性

- 支持多服务器配置管理
- 自动端口转发设置
- 连接超时和重试机制
- 保持连接活跃
- 彩色输出支持
- 环境变量配置

## 安装和使用

### 1. 配置文件设置

创建配置文件 `~/.ssh/port_forward.conf`：

```bash
# 格式: ID,Name,Host,Port,User,AuthType,AuthValue,PortMappings
web1,Web Server 1,192.168.1.10,22,root,key,~/.ssh/web1.key,8080:80,3306:3306
db1,Database Server 1,192.168.1.20,22,root,password,securepass123,3307:3306
```

### 2. 运行脚本

```bash
# 交互式选择服务器
./ssh_port_forward.exp

# 直接指定服务器ID
./ssh_port_forward.exp web1

# 使用环境变量指定服务器
export TARGET_SERVER_ID=web1
./ssh_port_forward.exp
```

## 超时问题解决方案

### 问题描述
如果遇到连接超时错误：
```
ERROR: Connection timeout
ERROR: Failed to connect after 3 attempts
```

### 解决方案

#### 1. 调整超时参数

设置环境变量来调整超时配置：

```bash
# 增加连接超时时间
export SSH_TIMEOUT=120
export SSH_CONNECTION_TIMEOUT=60

# 增加重试次数
export SSH_MAX_ATTEMPTS=5

# 调整保活设置
export SSH_ALIVE_INTERVAL=15
export SSH_ALIVE_COUNT=10
```

#### 2. 完整的超时配置示例

```bash
# 创建超时配置文件
cat > ~/.ssh/port_forward_timeout.sh << 'EOF'
#!/bin/bash
# SSH Port Forward 超时配置

# 基本超时设置
export SSH_TIMEOUT=120                    # Expect 超时时间 (秒)
export SSH_CONNECTION_TIMEOUT=60          # SSH 连接超时 (秒)
export SSH_MAX_ATTEMPTS=5                 # 最大重试次数

# 保活设置
export SSH_KEEP_ALIVE=1                   # 启用保活
export SSH_ALIVE_INTERVAL=15              # 保活间隔 (秒)
export SSH_ALIVE_COUNT=10                 # 保活计数
export SSH_TCP_KEEP_ALIVE=1               # 启用TCP保活

# 其他设置
export SSH_NO_COLOR=0                     # 启用彩色输出
EOF

# 使用配置
source ~/.ssh/port_forward_timeout.sh
./ssh_port_forward.exp
```

#### 3. 网络问题排查

如果仍然超时，检查以下问题：

1. **网络连接**
   ```bash
   ping <server_ip>
   telnet <server_ip> <ssh_port>
   ```

2. **防火墙设置**
   - 检查本地防火墙
   - 检查服务器防火墙
   - 检查网络设备防火墙

3. **SSH服务状态**
   ```bash
   # 在服务器上检查SSH服务
   sudo systemctl status sshd
   ```

4. **SSH配置**
   ```bash
   # 检查SSH客户端配置
   ssh -v <user>@<host> -p <port>
   ```

### 4. 高级配置

#### 针对慢速网络的配置

```bash
export SSH_TIMEOUT=300
export SSH_CONNECTION_TIMEOUT=120
export SSH_MAX_ATTEMPTS=3
export SSH_ALIVE_INTERVAL=30
export SSH_ALIVE_COUNT=5
```

#### 针对不稳定网络的配置

```bash
export SSH_TIMEOUT=60
export SSH_CONNECTION_TIMEOUT=30
export SSH_MAX_ATTEMPTS=10
export SSH_ALIVE_INTERVAL=10
export SSH_ALIVE_COUNT=15
```

## 环境变量说明

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `SSH_TIMEOUT` | 60 | Expect 超时时间 (秒) |
| `SSH_CONNECTION_TIMEOUT` | 30 | SSH 连接超时 (秒) |
| `SSH_MAX_ATTEMPTS` | 3 | 最大重试次数 |
| `SSH_KEEP_ALIVE` | 1 | 启用保活 (0/1) |
| `SSH_ALIVE_INTERVAL` | 30 | 保活间隔 (秒) |
| `SSH_ALIVE_COUNT` | 5 | 保活计数 |
| `SSH_TCP_KEEP_ALIVE` | 1 | 启用TCP保活 (0/1) |
| `SSH_NO_COLOR` | 0 | 禁用彩色输出 (0/1) |
| `PORT_FORWARD_CONFIG` | ~/.ssh/port_forward.conf | 配置文件路径 |
| `TARGET_SERVER_ID` | - | 目标服务器ID |
| `TARGET_SERVER_NUM` | - | 目标服务器编号 |

## 故障排除

### 常见错误及解决方案

1. **配置文件未找到**
   ```
   ERROR: Configuration file not found
   ```
   解决方案：创建配置文件或设置 `PORT_FORWARD_CONFIG` 环境变量

2. **认证失败**
   ```
   ERROR: Authentication failed
   ```
   解决方案：检查用户名、密码或SSH密钥

3. **连接被拒绝**
   ```
   ERROR: Connection refused
   ```
   解决方案：检查服务器状态、端口和防火墙设置

4. **主机名解析失败**
   ```
   ERROR: Name or service not known
   ```
   解决方案：检查主机地址是否正确

## 示例用法

### 基本用法
```bash
# 交互式连接
./ssh_port_forward.exp

# 直接连接指定服务器
./ssh_port_forward.exp web1

# 使用环境变量
export TARGET_SERVER_ID=web1
./ssh_port_forward.exp
```

### 高级用法
```bash
# 使用自定义配置文件
export PORT_FORWARD_CONFIG=/path/to/custom.conf
./ssh_port_forward.exp

# 调整超时设置
export SSH_TIMEOUT=120
export SSH_CONNECTION_TIMEOUT=60
./ssh_port_forward.exp web1
```

## 注意事项

1. 确保脚本有执行权限：`chmod +x ssh_port_forward.exp`
2. 确保系统已安装 Expect：`sudo apt-get install expect` (Ubuntu/Debian)
3. 配置文件中的路径支持 `~` 展开
4. 端口映射格式为 `local_port:remote_port`
5. 支持密钥和密码两种认证方式
