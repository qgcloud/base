#!/bin/bash

# 安装 Shadowsocks
echo "正在安装 Shadowsocks..."
sudo apt update
sudo apt install -y shadowsocks

# 创建配置文件
echo "正在创建配置文件..."
cat <<EOF | sudo tee /etc/shadowsocks.json
{
  "server": "0.0.0.0",
  "server_port": 1111,
  "password": "Aa778409",
  "timeout": 1000,
  "method": "aes-256-gcm"
}
EOF

# 启动 Shadowsocks 服务
echo "正在启动 Shadowsocks 服务..."
sudo systemctl restart shadowsocks
sudo systemctl enable shadowsocks

# 检查服务状态
echo "检查 Shadowsocks 服务状态..."
sudo systemctl status shadowsocks

echo "Shadowsocks 已成功安装并启动！"
