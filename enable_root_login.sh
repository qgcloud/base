#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 备份原始/root/.ssh/authorized_keys文件
cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
# 备份原始sshd_config文件
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
# 备份原始/etc/ssh/sshd_config.d/60-cloudimg-settings.conf文件
cp /etc/ssh/sshd_config.d/60-cloudimg-settings.conf /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak


if [ $? -ne 0 ]; then
    echo "备份原始文件失败" 1>&2
    exit 1
fi

# 编辑authorized_keys文件，将ssh-rsa之前的内容注释掉
if [ -f /root/.ssh/authorized_keys ]; then
    # 将ssh-rsa之前的内容注释掉
    sed -i '/^ssh-rsa/q;s/^/#/' /root/.ssh/authorized_keys
    if [ $? -ne 0 ]; then
        echo "编辑authorized_keys文件失败" 1>&2
        # 恢复原始/root/.ssh/authorized_keys文件
        cp /root/.ssh/authorized_keys.bak /root/.ssh/authorized_keys
        exit 1
    fi
else
    echo "/root/.ssh/authorized_keys 文件不存在" 1>&2
    # 恢复原始sshd_config文件
    cp /root/.ssh/authorized_keys.bak /root/.ssh/authorized_keys
    exit 1
fi

# 编辑sshd_config文件
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
if [ $? -ne 0 ]; then
    echo "编辑sshd_config文件失败" 1>&2
    # 恢复原始sshd_config文件
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
    exit 1
fi

# 编辑sshd_config.d/60-cloudimg-settings.conf文件
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
    if [ $? -ne 0 ]; then
        echo "编辑60-cloudimg-settings.conf文件失败" 1>&2
        # 恢复原始sshd_config文件
        cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        exit 1
    fi
else
    echo "/etc/ssh/sshd_config.d/60-cloudimg-settings.conf 文件不存在" 1>&2
    # 恢复原始sshd_config文件
    cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
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
        # 恢复原始sshd_config文件
        cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
        exit 1
    fi
fi


# 设置root密码
while true; do
    echo "设置root密码（不安全，通常不建议在脚本中设置密码）"
    passwd root
    if [ $? -eq 0 ]; then
        echo "root密码设置成功。"
        break
    else
        echo "密码输入错误，重新设置..."
    fi
done

echo "SSH配置已更新，允许root用户登录。"
