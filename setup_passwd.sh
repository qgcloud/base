#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
    echo "该脚本必须以 root 权限运行" 1>&2
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
