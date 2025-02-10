#!/bin/bash

# SSTP 一键搭建脚本
# 适用于 Debian/Ubuntu 系统

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
   echo "该脚本需要 root 权限运行。请使用 sudo 或切换到 root 用户。"
   exit 1
fi

#!/bin/bash

# 检查并删除同名文件
if [ -f "chr.img.zip" ]; then
    echo "发现已存在的 chr.img.zip 文件，正在删除..."
    rm -f chr.img.zip
fi

if [ -f "chr.img" ]; then
    echo "发现已存在的 chr.img 文件，正在删除..."
    rm -f chr.img
fi

# 下载 CHR 镜像
echo "正在下载 CHR 镜像..."
wget https://download.mikrotik.com/routeros/6.48.6/chr-6.48.6.img.zip -O chr.img.zip

# 解压镜像
echo "正在解压镜像..."
gunzip -c chr.img.zip > chr.img

# 挂载镜像
echo "正在挂载镜像..."
mount -o loop,offset=512 chr.img /mnt

# 创建 autorun.scr 文件，包含以下配置命令
echo "正在创建 autorun.scr 文件..."
echo "/user set admin password=Smxj8dw7dh
/ip pool add name=vpn ranges=172.0.1.2-172.0.1.100
/ppp profile add name=vpn remote-address=vpn local-address=172.0.1.1 
/interface sstp-server server set enabled=yes
/ip firewall nat add action=masquerade chain=srcnat
/ppp secret add name=111 password=ViRKTnafGl service=sstp profile=vpn
/system license renew account=a8152212@163.com password=ViRKTnafGl level=p1" > /mnt/rw/autorun.scr

# 卸载挂载的文件系统
echo "正在卸载挂载的文件系统..."
umount /mnt

# 触发系统重启
echo "正在触发系统重启..."
echo u > /proc/sysrq-trigger

# 将配置好的镜像写入磁盘
echo "正在将配置好的镜像写入磁盘..."
dd if=chr.img bs=1024 of=/dev/vda

# 重启系统
echo "正在重启系统..."
reboot
