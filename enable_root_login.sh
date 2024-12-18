#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 允许root登录
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config

# 允许密码认证
sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 重启SSH服务
systemctl restart sshd

# 设置root密码
echo "设置root密码"
passwd root

echo "root用户密码登录已启用"

# 定义一个函数来编辑sshd_config文件和重启SSH服务
update_ssh_config() {
    # 编辑sshd_config文件
    sed -i '/^ *Match/,/^ *command/c\# no-port-forwarding' /etc/ssh/sshd_config
    sed -i '/^ *Match/,/^ *command/c\# no-agent-forwarding' /etc/ssh/sshd_config
    sed -i '/^ *Match/,/^ *command/c\# no-X11-forwarding' /etc/ssh/sshd_config
    sed -i '/^ *Match/,/^ *command/c\# command="echo '\''Please login as the user \"ubuntu\" rather than the user \"root\".'\'';echo;sleep 10;exit 142"' /etc/ssh/sshd_config

    # 重启SSH服务
    systemctl restart sshd
}

# 备份原始sshd_config文件
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# 尝试更新SSH配置
update_ssh_config

# 检查是否有命令失败
if [ $? -ne 0 ]; then
    echo "SSH配置更新失败，正在恢复原始配置..."
    # 恢复原始sshd_config文件
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    # 重启SSH服务以应用原始配置
    systemctl restart sshd
    echo "原始配置已恢复。"
    exit 1
fi

# 输出提示信息
echo "SSH配置已更新，允许root用户登录。"
