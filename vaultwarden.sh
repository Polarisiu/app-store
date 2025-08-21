#!/bin/bash

# ========================================
# Vaultwarden 一键管理脚本
# 功能：启动/停止/更新/查看日志/卸载 + 自动显示公网访问地址
# ========================================

WORKDIR="$HOME/vaultwarden-data"
CONTAINER_NAME="vaultwarden"
IMAGE_NAME="vaultwarden/server:latest"
DOMAIN="https://vw.domain.tld"  # 请修改为你的域名
PORT=8000  # 容器映射端口，可改为你需要的端口

# 创建数据目录
mkdir -p "$WORKDIR"

# 获取公网 IP
get_public_ip() {
    IP=$(curl -s https://ifconfig.me)
    # 如果不是 IPv4 格式，则显示 "服务器IP"
    if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        IP="服务器IP"
    fi
    echo "$IP"
}

# 菜单函数
show_menu() {
    echo "===== Vaultwarden 管理菜单 ====="
    echo "1. 启动 Vaultwarden"
    echo "2. 停止 Vaultwarden"
    echo "3. 更新 Vaultwarden"
    echo "4. 查看日志"
    echo "5. 卸载 Vaultwarden"
    echo "6. 退出"
    echo "================================"
}

while true; do
    show_menu
    read -rp "请选择操作 [1-6]: " choice
    case $choice in
        1)
            echo "启动 Vaultwarden..."
            docker run -d \
                --name $CONTAINER_NAME \
                --env DOMAIN="$DOMAIN" \
                --volume "$WORKDIR:/data/" \
                --restart unless-stopped \
                -p 0.0.0.0:$PORT:80 \
                $IMAGE_NAME
            echo "Vaultwarden 已启动"

            IP=$(get_public_ip)
            echo "访问地址：http://$IP:$PORT"
            ;;
        2)
            echo "停止 Vaultwarden..."
            docker stop $CONTAINER_NAME
            ;;
        3)
            echo "更新 Vaultwarden..."
            docker stop $CONTAINER_NAME
            docker rm $CONTAINER_NAME
            docker pull $IMAGE_NAME
            docker run -d \
                --name $CONTAINER_NAME \
                --env DOMAIN="$DOMAIN" \
                --volume "$WORKDIR:/data/" \
                --restart unless-stopped \
                -p 0.0.0.0:$PORT:80 \
                $IMAGE_NAME
            echo "Vaultwarden 已更新并启动"

            IP=$(get_public_ip)
            echo "访问地址：http://$IP:$PORT"
            ;;
        4)
            echo "查看日志（Ctrl+C 退出）"
            docker logs -f $CONTAINER_NAME
            ;;
        5)
            read -rp "确认卸载 Vaultwarden 并删除数据吗？[y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker stop $CONTAINER_NAME
                docker rm $CONTAINER_NAME
                rm -rf "$WORKDIR"
                echo "Vaultwarden 已卸载"
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
