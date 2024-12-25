#!/bin/bash

sudo -i


# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 备份原始文件
cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
cp /etc/ssh/sshd_config.d/60-cloudimg-settings.conf /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak

# 编辑authorized_keys文件，将ssh-rsa之前的字符全部删掉
if ! sed -i '/^ssh-rsa/i \\\n' /root/.ssh/authorized_keys && sed -i '/^ssh-rsa/q;s/^/#/' /root/.ssh/authorized_keys; then
    echo "编辑/root/.ssh/authorized_keys文件失败" 1>&2
    restore_backup
    exit 1
fi

# 编辑sshd_config文件
if ! sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; then
    echo "编辑/etc/ssh/sshd_config文件失败，替换PermitRootLogin配置" 1>&2
    restore_backup
    exit 1
fi
if ! sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config; then
    echo "编辑/etc/ssh/sshd_config文件失败，替换PasswordAuthentication配置" 1>&2
    restore_backup
    exit 1
fi

# 编辑60-cloudimg-settings.conf文件
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
        # 恢复原始文件
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
