#!/bin/bash

# ========================================
# Nexus Terminal 一键管理脚本
# 功能：自动检查配置文件 + 菜单管理 + 启动后显示访问地址（端口固定18111）
# ========================================

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

# 工作目录
WORKDIR="$HOME/nexus-terminal"

# 创建工作目录（如果不存在）
if [ ! -d "$WORKDIR" ]; then
    mkdir -p "$WORKDIR"
    echo -e "${GREEN}已创建工作目录：$WORKDIR${RESET}"
fi

cd "$WORKDIR" || exit

# 检查 docker-compose.yml 是否存在，不存在就下载
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${BLUE}docker-compose.yml 文件不存在，正在下载...${RESET}"
    wget -q https://raw.githubusercontent.com/Heavrnl/nexus-terminal/refs/heads/main/docker-compose.yml -O docker-compose.yml
    if [ $? -ne 0 ]; then
        echo -e "${RED}docker-compose.yml 下载失败，请检查网络${RESET}"
        exit 1
    fi
fi

# 检查 .env 文件是否存在，不存在就下载
if [ ! -f ".env" ]; then
    echo -e "${BLUE}.env 文件不存在，正在下载...${RESET}"
    wget -q https://raw.githubusercontent.com/Heavrnl/nexus-terminal/refs/heads/main/.env -O .env
    if [ $? -ne 0 ]; then
        echo -e "${RED}.env 下载失败，请检查网络${RESET}"
        exit 1
    fi
fi

# 获取公网 IP 函数
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
    echo -e "${CYAN}================ Nexus Terminal 管理菜单 ================${RESET}"
    echo -e "${YELLOW}1.${RESET} 启动服务"
    echo -e "${YELLOW}2.${RESET} 停止服务"
    echo -e "${YELLOW}3.${RESET} 更新服务"
    echo -e "${YELLOW}4.${RESET} 查看日志"
    echo -e "${YELLOW}5.${RESET} 卸载服务"
    echo -e "${YELLOW}6.${RESET} 退出"
    echo -e "${CYAN}======================================================${RESET}"
}

# 菜单循环
while true; do
    show_menu
    read -rp "请选择操作 [1-6]: " choice
    case $choice in
        1)
            echo -e "${GREEN}启动服务中...${RESET}"
            docker compose up -d
            echo -e "${GREEN}服务已启动${RESET}"

            # 获取公网 IP 并显示访问地址
            IP=$(get_public_ip)
            PORT=18111  # 固定端口
            echo -e "${GREEN}访问地址：http://$IP:$PORT${RESET}"
            ;;
        2)
            echo -e "${RED}停止服务中...${RESET}"
            docker compose down
            echo -e "${RED}服务已停止${RESET}"
            ;;
        3)
            echo -e "${BLUE}更新服务中...${RESET}"
            docker compose down
            docker compose pull
            docker compose up -d
            echo -e "${GREEN}服务已更新并启动${RESET}"

            # 获取公网 IP 并显示访问地址
            IP=$(get_public_ip)
            PORT=18111
            echo -e "${GREEN}访问地址：http://$IP:$PORT${RESET}"
            ;;
        4)
            echo -e "${CYAN}显示日志（Ctrl+C 退出）${RESET}"
            docker compose logs -f
            ;;
        5)
            read -rp "确认卸载服务并删除所有数据吗？[y/N]: " confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${RED}卸载中...${RESET}"
                docker compose down --rmi all --volumes --remove-orphans
                cd "$HOME" || exit
                rm -rf "$WORKDIR"
                echo -e "${GREEN}服务已卸载，工作目录已删除${RESET}"
                exit 0
            else
                echo -e "${YELLOW}取消卸载${RESET}"
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
