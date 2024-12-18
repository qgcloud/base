#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 备份原始sshd_config文件
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
cp /etc/ssh/sshd_config.d/60-cloudimg-settings.conf /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak

# 定义一个函数来编辑sshd_config文件和重启SSH服务
update_ssh_config() {
# 编辑authorized_keys文件，将ssh-rsa之前的内容注释掉
if [ -f /root/.ssh/authorized_keys ]; then
    # 将ssh-rsa之前的内容注释掉
    sed -i '/^ssh-rsa/q;s/^/#/' /root/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
        echo "编辑authorized_keys文件失败" 1>&2
        # 恢复原始sshd_config文件
        cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        exit 1
    fi
else
    echo "/root/.ssh/authorized_keys 文件不存在" 1>&2
    # 恢复原始sshd_config文件
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    exit 1
fi


    # 编辑sshd_config文件
    sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

    # 注释掉Include指令
    sed -i 's/^#*Include /etc/ssh/sshd_config.d/\*.conf/#&/' /etc/ssh/sshd_config

    # 编辑60-cloudimg-settings.conf文件
    sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf

    # 重启SSH服务
    systemctl restart sshd
}

# 尝试更新SSH配置
if update_ssh_config; then
    echo "SSH配置已更新，允许root用户登录。"
else
    echo "SSH配置更新失败，正在恢复原始配置..."
    # 恢复原始sshd_config文件
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    cp /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
    # 重启SSH服务以应用原始配置
    systemctl restart sshd
    echo "原始配置已恢复。"
    exit 1
fi
