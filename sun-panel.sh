#!/bin/bash

WORKDIR="$HOME/docker_data/sun-panel"
CONTAINER_NAME="sun-panel"
IMAGE_NAME="hslr/sun-panel:latest"
PORT=3002

mkdir -p "$WORKDIR/conf"

get_public_ip() {
    IP=$(curl -s https://ifconfig.me)
    if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        IP="服务器IP"
    fi
    echo "$IP"
}

show_menu() {
    echo "===== Sun Panel 管理菜单 ====="
    echo "1. 启动 Sun Panel"
    echo "2. 停止 Sun Panel"
    echo "3. 更新 Sun Panel"
    echo "4. 查看日志"
    echo "5. 卸载 Sun Panel"
    echo "6. 退出"
    echo "=============================="
}

while true; do
    show_menu
    read -rp "请选择操作 [1-6]: " choice
    case $choice in
        1)
            echo "启动 Sun Panel..."
            docker run -d --restart=always \
                -p 0.0.0.0:$PORT:$PORT \
                -v "$WORKDIR/conf":/app/conf \
                -v /var/run/docker.sock:/var/run/docker.sock \
                --name $CONTAINER_NAME \
                $IMAGE_NAME
            echo "Sun Panel 已启动"

            IP=$(get_public_ip)
            echo "访问地址：http://$IP:$PORT"
            ;;
        2)
            echo "停止 Sun Panel..."
            docker stop $CONTAINER_NAME
            ;;
        3)
            echo "更新 Sun Panel..."
            docker stop $CONTAINER_NAME
            docker rm $CONTAINER_NAME
            docker pull $IMAGE_NAME
            docker run -d --restart=always \
                -p 0.0.0.0:$PORT:$PORT \
                -v "$WORKDIR/conf":/app/conf \
                -v /var/run/docker.sock:/var/run/docker.sock \
                --name $CONTAINER_NAME \
                $IMAGE_NAME
            echo "Sun Panel 已更新并启动"

            IP=$(get_public_ip)
            echo "访问地址：http://$IP:$PORT"
            ;;
        4)
            echo "查看日志（Ctrl+C 退出）"
            docker logs -f $CONTAINER_NAME
            ;;
        5)
            read -rp "确认卸载 Sun Panel 并删除数据吗？[y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker stop $CONTAINER_NAME
                docker rm $CONTAINER_NAME
                rm -rf "$WORKDIR"
                echo "Sun Panel 已卸载"
                exit 0
            fi
            ;;
        6)
            echo "退出脚本"
            exit 0
            ;;
        *)
            echo "输入错误，请重新选择"
            ;;
    esac
done
