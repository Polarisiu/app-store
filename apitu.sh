#!/bin/bash

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

# docker-compose 文件名
DC_FILE="docker-compose.yml"

# 获取服务器公网 IP
get_ip() {
    # 尝试获取公网 IP
    IP=$(curl -s https://api.ipify.org)
    if [[ -z "$IP" ]]; then
        IP="localhost"
    fi
    echo "$IP"
}

menu() {
    clear
    echo -e "${RED}=== 随机图片 API 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 一键部署 API${RESET}"
    echo -e "${GREEN}2) 启动 API${RESET}"
    echo -e "${GREEN}3) 停止 API${RESET}"
    echo -e "${GREEN}4) 重启 API${RESET}"
    echo -e "${GREEN}5) 查看日志${RESET}"
    echo -e "${GREEN}6) 卸载 API${RESET}"
    echo -e "${GREEN}7) 查看访问方式${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    echo
    read -p "请输入选项: " choice
}

deploy() {
    read -p "请输入你的图床地址: " LSKY_API_URL
    read -p "请输入你的兰空图床 Token: " LSKY_TOKEN
    read -p "请输入自定义标题: " CUSTOM_TITLE

    cat > $DC_FILE <<EOF
version: '3'
services:
  random-image-api:
    image: libyte/random-image-api:latest
    ports:
      - "3007:3007"
    environment:
      - LSKY_API_URL=${LSKY_API_URL}
      - LSKY_TOKEN=${LSKY_TOKEN}
      - CUSTOM_TITLE=${CUSTOM_TITLE}
EOF

    echo -e "${GREEN}docker-compose.yml 已生成，正在启动容器...${RESET}"
    docker compose up -d

    show_access
}

start_api() {
    docker compose up -d
    echo -e "${GREEN}API 已启动${RESET}"
}

stop_api() {
    docker compose down
    echo -e "${YELLOW}API 已停止${RESET}"
}

restart_api() {
    docker compose down
    docker compose up -d
    echo -e "${GREEN}API 已重启${RESET}"
}

view_logs() {
    docker compose logs -f
}

uninstall_api() {
    read -p $'\033[31m⚠️ 确认要卸载 API 并删除所有文件吗？(y/n): \033[0m' confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker compose down
        rm -f $DC_FILE
        echo -e "${RED}API 已卸载，docker-compose.yml 已删除${RESET}"
    else
        echo -e "${YELLOW}已取消卸载${RESET}"
    fi
}

show_access() {
    IP=$(get_ip)
    echo -e "${GREEN}\n🌐 访问方式${RESET}"
    echo -e "${GREEN}主页预览：http://${IP}:3007/  - 好看的图片页面${RESET}"
    echo -e "${GREEN}直接图片：http://${IP}:3007/api  - 纯图片，刷新换图${RESET}"
    echo -e "${GREEN}JSON 数据：http://${IP}:3007/?format=json  - 程序调用${RESET}\n"
}

while true; do
    menu
    case $choice in
        1) deploy ;;
        2) start_api ;;
        3) stop_api ;;
        4) restart_api ;;
        5) view_logs ;;
        6) uninstall_api ;;
        7) show_access ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项，请重新选择${RESET}" ;;
    esac
    echo
    read -p "按回车继续..." dummy
done
