#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

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
