#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 备份原始文件
cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cp /etc/ssh/sshd_config.d/60-cloudimg-settings.conf /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak

# 编辑authorized_keys文件，在第一个ssh-rsa之前插入换行符，并注释掉之前的所有行
if ! sed -i 's/ssh-rsa/\n&/g' /root/.ssh/authorized_keys; then
    echo "在第一个ssh-rsa之前插入换行符失败" 1>&2
    restore_backup
    exit 1
fi

if ! sed -i '/^ssh-rsa/q;s/^/#/' /root/.ssh/authorized_keys; then
    echo "注释/root/.ssh/authorized_keys文件中的行失败" 1>&2
    restore_backup
    exit 1
fi


# 编辑sshd_config文件，在文件末尾添加PermitRootLogin yes和PasswordAuthentication yes
{
    echo "PermitRootLogin yes"
    echo "PasswordAuthentication yes"
} >> /etc/ssh/sshd_config

# 检查添加操作是否成功
if [ $? -eq 0 ]; then
    echo "/etc/ssh/sshd_config配置已成功更新。"
else
    echo "更新/etc/ssh/sshd_config配置失败。" 1>&2
    # 恢复原始sshd_config文件
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    exit 1
fi

# 编辑60-cloudimg-settings.conf文件，将PasswordAuthentication no替换为PasswordAuthentication yes
if ! sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf; then
    echo "编辑/etc/ssh/sshd_config.d/60-cloudimg-settings.conf文件失败" 1>&2
    restore_backup
    exit 1
fi



# 重启SSH服务
if systemctl restart sshd.service &>/dev/null; then
    echo "SSH服务已成功重启。"
else
    echo "尝试重启SSH服务失败，尝试使用'ssh'作为服务名称。"
    if systemctl restart ssh.service &>/dev/null; then
        echo "SSH服务已成功重启。"
    else
        echo "重启SSH服务失败。" 1>&2
        restore_backup
        exit 1
    fi
fi

echo "SSH配置已更新。"

# 定义一个函数来恢复备份文件
restore_backup() {
    cp /root/.ssh/authorized_keys.bak /root/.ssh/authorized_keys
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    cp /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
    echo "已还原所有原始文件。"
}
