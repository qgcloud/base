#!/bin/bash


# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi


# 检查脚本是否已经存在
if [ -f ~/setup_chinese.sh ]; then
    echo "检测到旧脚本，正在删除..."
    rm ~/setup_chinese.sh
fi

# 下载新的脚本
echo "下载新的设置中文显示脚本..."
wget -qO ~/setup_chinese.sh https://raw.githubusercontent.com/qgcloud/base/main/setup_chinese.sh

# 给予执行权限
chmod +x ~/setup_chinese.sh

# 执行脚本
echo "执行设置中文显示脚本..."
~/setup_chinese.sh
