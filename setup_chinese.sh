#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 更新系统包列表
echo "更新系统包列表..."
apt update

# 安装中文语言包
echo "安装中文语言包..."
apt install -y language-pack-zh-hans language-pack-zh-hant

# 安装中文字体
echo "安装中文字体..."
apt install -y fonts-wqy-zenhei fonts-wqy-microhei

# 配置终端字符集
echo "配置终端字符集..."
echo "export LANG=zh_CN.UTF-8" >> /etc/profile
source /etc/profile

# 配置区域设置为中文
echo "配置区域设置为中文..."
localectl set-locale LANG=zh_CN.UTF-8


# 清除字体缓存
echo "清除字体缓存..."
fc-cache -fv

echo "重启系统以应用更改..."
read -p "选择1重启，选择2不重启，脚本运行结束: " choice

if [ "$choice" = "1" ]; then
    echo "正在重启系统..."
    reboot
elif [ "$choice" = "2" ]; then
    echo "脚本运行结束，不重启系统。"
else
    echo "无效的输入，脚本运行结束。"
fi
