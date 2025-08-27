#!/bin/bash
# ========================================
# Trilium 中文版 一键部署 & 菜单管理脚本
# ========================================

GREEN="\033[0;32m"
RESET="\033[0m"

COMPOSE_FILE="docker-compose.yml"
PORT_FILE=".trilium_port"

if [ "$EUID" -ne 0 ]; then
    echo -e "${GREEN}请使用 root 权限运行脚本！${RESET}"
    exit 1
fi

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${GREEN}未检测到 Docker，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | sh
    fi
    if ! command -v docker-compose &>/dev/null; then
        echo -e "${GREEN}未检测到 Docker Compose，正在安装...${RESET}"
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
}

deploy_trilium() {
    read -p "请输入映射端口 (默认8080): " PORT
    PORT=${PORT:-8080}
    echo "$PORT" > $PORT_FILE

    cat > $COMPOSE_FILE <<EOF
services:
  trilium-cn:
    image: nriver/trilium-cn
    restart: always
    ports:
      - "$PORT:8080"
    volumes:
      - ./trilium-data:/root/trilium-data
    environment:
      - TRILIUM_DATA_DIR=/root/trilium-data
EOF

    echo -e "${GREEN}docker-compose.yml 已生成，端口: $PORT${RESET}"
    docker-compose up -d
    echo -e "${GREEN}Trilium 已部署！访问: http://<127.0.0.1>:$PORT${RESET}"
}

start_service() {
    docker-compose up -d
    local port=$(cat $PORT_FILE 2>/dev/null || echo 8080)
    echo -e "${GREEN}Trilium 已启动！访问: http://<127.0.0.1>:$port${RESET}"
}

stop_service() {
    docker-compose down
    echo -e "${GREEN}Trilium 已停止！${RESET}"
}

restart_service() {
    docker-compose down && docker-compose up -d
    local port=$(cat $PORT_FILE 2>/dev/null || echo 8080)
    echo -e "${GREEN}Trilium 已重启！访问: http://<服务器IP>:$port${RESET}"
}

view_logs() {
    docker-compose logs --tail=50
    echo -e "${GREEN}（仅显示最近50行日志）${RESET}"
}

status_service() {
    docker-compose ps
}

update_service() {
    docker-compose pull
    docker-compose up -d
    local port=$(cat $PORT_FILE 2>/dev/null || echo 8080)
    echo -e "${GREEN}Trilium 已更新并重启！访问: http://<127.0.0.1>:$port${RESET}"
}

remove_all() {
    docker-compose down -v
    rm -rf trilium-data $COMPOSE_FILE $PORT_FILE
    echo -e "${GREEN}Trilium 及数据已删除！${RESET}"
}

menu() {
    clear
    echo -e "${GREEN}========================================${RESET}"
    echo -e "${GREEN}     Trilium 中文版 一键部署管理菜单    ${RESET}"
    echo -e "${GREEN}========================================${RESET}"
    echo -e "${GREEN}1) 安装 部署${RESET}"
    echo -e "${GREEN}2) 启动 Trilium${RESET}"
    echo -e "${GREEN}3) 停止 Trilium${RESET}"
    echo -e "${GREEN}4) 重启 Trilium${RESET}"
    echo -e "${GREEN}5) 查看日志${RESET}"
    echo -e "${GREEN}6) 查看状态${RESET}"
    echo -e "${GREEN}7) 更新 Trilium${RESET}"
    echo -e "${GREEN}8) 删除 Trilium 及数据${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    echo -e "${GREEN}========================================${RESET}"
}

while true; do
    menu
    read -p "请输入选项: " choice
    case $choice in
        1) check_docker; deploy_trilium ;;
        2) start_service ;;
        3) stop_service ;;
        4) restart_service ;;
        5) view_logs ;;
        6) status_service ;;
        7) update_service ;;
        8) remove_all ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选项，请重新输入！${RESET}" ;;
    esac
    read -p "按回车返回菜单..."
done
