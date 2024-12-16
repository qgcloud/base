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
wget -qO ~/setup_chinese.sh https://raw.githubusercontent.com/qgcloud/base/refs/heads/main/setup_chinese.sh

# 给予执行权限
chmod +x ~/setup_chinese.sh

# 执行脚本
echo "执行设置中文显示脚本..."
~/setup_chinese.sh


# 更新系统包列表
echo "更新系统包列表..."
apt update

# 安装中文语言包和中文字体
echo "安装中文语言包和中文字体..."
apt install -y language-pack-zh-hans language-pack-zh-hant fonts-wqy-zenhei fonts-wqy-microhei

# 配置区域设置为中文
echo "配置区域设置为中文..."
localectl set-locale LANG=zh_CN.UTF-8

# 清除字体缓存
echo "清除字体缓存..."
fc-cache -fv

# 验证中文显示
echo "验证中文显示..."
echo "如果以下中文能正确显示，则设置成功："
echo "测试中文显示"
