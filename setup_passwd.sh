#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
    echo "该脚本必须以 root 权限运行" 1>&2
    exit 1
fi

# 设置新密码
new_password='qgcloude@'

# 使用 expect -c 自动设置密码，并处理潜在的错误
expect -c "
set timeout -1
spawn passwd root
expect {
    \"Enter new UNIX password:\" { send -- \"$new_password\r\"; exp_continue }
    \"Retype new UNIX password:\" { send -- \"$new_password\r\"; exp_continue }
    \"password changed successfully\" { puts \"密码设置成功\"; exit 0 }
    eof { puts \"密码设置失败\"; exit 1 }
}
"

if [ $? -eq 0 ]; then
    echo "root 密码设置成功。"
else
    echo "设置密码时出错。"
    exit 1
fi
