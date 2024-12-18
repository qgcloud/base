#!/bin/bash


# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi


# 用户选择设置密码的方式
echo "请选择一个选项来设置 root 密码："
echo "1. 使用默认密码 'qgcloude@'"
echo "2. 自主设置密码"
echo "3. 生成随机密码并保存到 /root/password.txt"
read -p "请输入选项 (1/2/3): " option

case $option in
    1)
        echo "qgcloude@" | passwd --stdin root
        echo "已使用默认密码 'qgcloude@' 设置 root 密码。"
        ;;
    2)
        echo "请输入新的 root 密码："
        passwd root
        echo "您已自主设置 root 密码。"
        ;;
    3)
        new_password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 12 | head -n 1)
        echo $new_password | passwd --stdin root
        echo "$new_password" > /root/password.txt
        echo "生成的密码: $new_password"
        echo "密码已保存到 /root/password.txt。"
        ;;
    *)
        echo "无效的选项。"
        ;;
esac
