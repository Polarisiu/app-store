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

# ========== 颜色 ==========
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# 菜单函数
show_menu() {
    echo -e "${GREEN}===== Vaultwarden 管理菜单 =====${RESET}"
    echo -e "${GREEN}1. 启动 Vaultwarden${RESET}"
    echo -e "${GREEN}2. 停止 Vaultwarden${RESET}"
    echo -e "${GREEN}3. 更新 Vaultwarden${RESET}"
    echo -e "${GREEN}4. 查看日志${RESET}"
    echo -e "${GREEN}5. 卸载 Vaultwarden${RESET}"
    echo -e "${GREEN}6. 退出${RESET}"
    echo -e "${GREEN}================================${RESET}"
}

while true; do
    show_menu
    echo -ne "${YELLOW}请选择操作 [1-6]: ${RESET}"
    read -r choice
    case $choice in
        1)
            echo -e "${GREEN}启动 Vaultwarden...${RESET}"
            docker run -d \
                --name $CONTAINER_NAME \
                --env DOMAIN="$DOMAIN" \
                --volume "$WORKDIR:/data/" \
                --restart unless-stopped \
                -p 0.0.0.0:$PORT:80 \
                $IMAGE_NAME
            echo -e "${GREEN}Vaultwarden 已启动${RESET}"

            IP=$(get_public_ip)
            echo -e "${GREEN}访问地址：http://$IP:$PORT${RESET}"
            ;;
        2)
            echo -e "${GREEN}停止 Vaultwarden...${RESET}"
            docker stop $CONTAINER_NAME
            ;;
        3)
            echo -e "${GREEN}更新 Vaultwarden...${RESET}"
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
            echo -e "${GREEN}Vaultwarden 已更新并启动${RESET}"

            IP=$(get_public_ip)
            echo -e "${GREEN}访问地址：http://$IP:$PORT${RESET}"
            ;;
        4)
            echo -e "${GREEN}查看日志（Ctrl+C 退出）${RESET}"
            docker logs -f $CONTAINER_NAME
            ;;
        5)
            echo -ne "${YELLOW}确认卸载 Vaultwarden 并删除数据吗？[y/N]: ${RESET}"
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                docker stop $CONTAINER_NAME
                docker rm $CONTAINER_NAME
                rm -rf "$WORKDIR"
                echo -e "${GREEN}Vaultwarden 已卸载${RESET}"
                exit 0
            fi
            ;;
        6)
            echo -e "${YELLOW}退出脚本${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}输入错误，请重新选择${RESET}"
            ;;
    esac
done
