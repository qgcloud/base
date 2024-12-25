#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 备份原始文件
cp /root/.ssh/authorized_keys /root/.ssh/authorized_keys.bak
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
    cp /etc/ssh/sshd_config.d/60-cloudimg-settings.conf /etc/ssh/sshd_config.d/60-cloudimg-settings.conf.bak
fi

# 删除authorized_keys中ssh-rsa之前的行
sed -i '/^ssh-rsa/q;d' /root/.ssh/authorized_keys

# 编辑sshd_config文件
sed -i 's/^PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# 编辑60-cloudimg-settings.conf文件
if [ -f /etc/ssh/sshd_config.d/60-cloudimg-settings.conf ]; then
    sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
else
    # 如果文件不存在，则注释掉Include指令
    sed -i '/Include \/etc\/ssh\/sshd_config.d\/\*.conf/s/^/#/' /etc/ssh/sshd_config
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




echo "SSH配置已更新，允许root用户登录。"
