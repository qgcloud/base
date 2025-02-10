#!/bin/bash

# SSTP 一键搭建脚本
# 适用于 Debian/Ubuntu 系统

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本需要 root 权限运行。请使用 sudo 或切换到 root 用户。"
   exit 1
fi

# 更新系统
echo "正在更新系统..."
apt update && apt upgrade -y

# 安装必要的软件包
echo "正在安装 SSTP 服务器所需软件..."
apt install -y sstp-server sstp-client

# 配置 SSTP 服务器
echo "正在配置 SSTP 服务器..."
cat <<EOF > /etc/sstp/sstp.conf
[sstp-server]
port = 443
allow = 0.0.0.0/0
EOF

# 配置 PPP 选项
cat <<EOF > /etc/ppp/sstp-options
require-mschap-v2
ms-dns 8.8.8.8
ms-dns 8.8.4.4
EOF

# 添加 PPP 用户
cat <<EOF > /etc/ppp/chap-secrets
# Secrets for authentication using CHAP
# client    server  secret                  IP addresses
user        *       passwd                  *
EOF

# 重启 SSTP 服务
echo "正在重启 SSTP 服务..."
systemctl restart sstp-server

# 输出完成信息
echo "SSTP 服务器搭建完成！"
echo "用户名: user"
echo "密码: passwd"
echo "请确保您的防火墙允许 TCP 端口 443 的流量。"
