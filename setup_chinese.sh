#!/bin/bash

# 确保脚本以 root 用户权限运行
if [ "$(id -u)" != "0" ]; then
   echo "该脚本需要以 root 用户权限运行" 1>&2
   exit 1
fi

# 检测Linux发行版并安装中文语言包
if [ -f /etc/os-release ]; then
    # 读取发行版信息
    . /etc/os-release
    case "$ID" in
        "ubuntu"|"debian")
            echo "安装中文语言包..."
            apt-get update && apt-get install -y language-pack-zh-hans
            ;;
        "centos"|"rhel"|"fedora")
            echo "安装中文语言包..."
            yum install -y glibc-langpack-zh
            ;;
        *)
            echo "不支持的Linux发行版"
            exit 1
            ;;
    esac
else
    echo "无法检测Linux发行版"
    exit 1
fi

# 设置系统字符集为 UTF-8 支持中文
echo "设置系统字符集..."
localedef -i zh_CN -f UTF-8 zh_CN.UTF-8

# 配置 /etc/locale.conf 文件以设置 LANG 环境变量
echo "配置 /etc/locale.conf 文件..."
echo "LANG=zh_CN.UTF-8" >> /etc/locale.conf

# 应用语言环境设置
echo "应用语言环境设置..."
source /etc/locale.conf

# 安装中文字体
echo "安装中文字体..."
if [ "$ID" = "ubuntu" ] || [ "$ID" = "debian" ]; then
    apt-get install -y fonts-wqy-zenhei
else
    yum install -y glibc-langpack-zh glibc-langpack-zh-gnome
fi

# 创建一个包含中文的测试文件
echo "创建中文测试文件..."
echo "这是一段中文测试内容。" > /root/test-chinese.txt

# 提示用户检查中文显示
echo "请检查 /root/test-chinese.txt 文件以确认中文显示是否正常。"
echo "如果中文显示正常，则设置成功。"
