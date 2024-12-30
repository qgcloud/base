#!/bin/bash

# 服务器上的目录路径
SERVER_DIR="/root/client.ovpn"  # 替换为你的服务器目录路径

# 本地计算机上的目录路径
LOCAL_DIR="C:\Users\xyf19\Desktop\我要活过来"   # 替换为你的本地目录路径

# 使用 rsync 同步服务器上的文件夹到本地
rsync -avz -e ssh $SERVER_DIR/ localhost:$LOCAL_DIR
