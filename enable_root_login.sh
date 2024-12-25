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

# 显示菜单
echo "请选择一个选项来设置 root 密码："
echo "1. 使用默认密码 'qgcloude@'"
echo "2. 自主设置密码"
echo "3. 生成随机密码并保存到 /root/password.txt"

read -p "请输入选项 (1/2/3): " choice

# 如果没有选择任何选项，默认使用选项 1
if [ -z "$choice" ] || [ "$choice" = "1" ]; then
    choice=1
    echo "未选择任何选项，将使用默认密码。"
fi

case $choice in
    1)
        # 选项 1：使用默认密码
        new_password='qgcloude@'
        echo "使用默认密码: $new_password"

        # 使用 expect 设置密码
        expect -c "
        set timeout -1
        spawn passwd root
        expect \"Enter new UNIX password:\"
        send -- \"$new_password\r\"
        expect \"Retype new UNIX password:\"
        send -- \"$new_password\r\"
        expect eof
        "
        if [ $? -eq 0 ]; then
            echo "root 密码设置成功。"
        else
            echo "设置密码时出错。"
            exit 1
        fi
        ;;

    2)
        # 选项 2：自主设置密码
        while true; do
            read -s -p "请输入新的 root 密码: " new_password
            echo
            read -s -p "请再次输入新的 root 密码以确认: " confirm_password
            echo

            if [ "$new_password" = "$confirm_password" ]; then
                echo "使用用户指定的密码: $new_password"

                # 使用 expect 设置密码
                expect -c "
                set timeout -1
                spawn passwd root
                expect \"Enter new UNIX password:\"
                send -- \"$new_password\r\"
                expect \"Retype new UNIX password:\"
                send -- \"$new_password\r\"
                expect eof
                "
                if [ $? -eq 0 ]; then
                    echo "root 密码设置成功。"
                    break
                else
                    echo "设置密码时出错。请重新尝试。"
                fi
            else
                echo "两次输入的密码不一致。请重新输入。"
            fi
        done
        ;;

    3)
        # 选项 3：生成随机密码并保存到 /root/password.txt
        new_password=$(openssl rand -base64 12 | tr -d /=+ | fold -w 8 | head -n 1 | sed 's/\(.\{7\}\).*/\1@/')
        echo "生成的密码: $new_password"

        # 保存密码到 /root/password.txt
        echo "$new_password" > /root/password.txt
        if [ $? -eq 0 ]; then
            echo "密码已保存到 /root/password.txt。"

            # 使用 expect 设置密码
            expect -c "
            set timeout -1
            spawn passwd root
            expect \"Enter new UNIX password:\"
            send -- \"$new_password\r\"
            expect \"Retype new UNIX password:\"
            send -- \"$new_password\r\"
            expect eof
            "
            if [ $? -eq 0 ]; then
                echo "root 密码设置成功。"
            else
                echo "设置密码时出错。"
                exit 1
            fi
        else
            echo "无法将密码保存到 /root/password.txt。请检查权限。"
            exit 1
        fi
        ;;

    *)
        echo "无效的选项。请重新运行脚本并选择 1、2 或 3。"
        exit 1
        ;;
esac


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
