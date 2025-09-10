#!/bin/bash
# ============================================
# Termix 一键管理脚本 (仅自定义端口)
# 功能: 安装/更新/卸载/查看日志
# ============================================

APP_NAME="termix"
COMPOSE_FILE="docker-compose.yml"
IMAGE_NAME="ghcr.io/lukegus/termix:latest"
DATA_DIR="./termix-data"

GREEN="\033[32m"
RESET="\033[0m"

check_env() {
    if ! command -v docker &> /dev/null; then
        echo -e "${GREEN}❌ 未检测到 Docker，请先安装 Docker${RESET}"
        exit 1
    fi
    if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}❌ 未检测到 docker-compose，请先安装 docker-compose${RESET}"
        exit 1
    fi
}

generate_compose() {
    cat > $COMPOSE_FILE <<EOF
services:
  $APP_NAME:
    image: $IMAGE_NAME
    container_name: $APP_NAME
    restart: unless-stopped
    ports:
      - "$PORT:$PORT"
    volumes:
      - "$(realpath $DATA_DIR):/app/data"
    environment:
      PORT: "$PORT"
EOF
}

install_app() {
    read -p "请输入映射端口 (默认 8080): " PORT
    PORT=${PORT:-8080}

    mkdir -p "$DATA_DIR"

    echo -e "${GREEN}🚀 正在安装并启动 $APP_NAME (端口: $PORT) ...${RESET}"

    generate_compose
    docker compose up -d
    echo -e "${GREEN}✅ $APP_NAME 已启动，访问地址: http://$(curl -s https://api.ipify.org):$PORT${RESET}"
}

update_app() {
    echo -e "${GREEN}🔄 正在更新 $APP_NAME ...${RESET}"
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ 容器已更新并启动${RESET}"
}

uninstall_app() {
    read -p "⚠️ 确认要卸载 $APP_NAME 并删除数据吗？(y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker compose down -v
        rm -f $COMPOSE_FILE
        echo -e "${GREEN}✅ $APP_NAME 已卸载并清理${RESET}"
    else
        echo -e "${GREEN}❌ 已取消${RESET}"
    fi
}

logs_app() {
    docker logs -f $APP_NAME
}

menu() {
    clear
    echo -e "${GREEN}=== Termix 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装/启动 Termix${RESET}"
    echo -e "${GREEN}2) 更新 Termix${RESET}"
    echo -e "${GREEN}3) 卸载 Termix${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    echo -e "${GREEN}========================${RESET}"
    read -p "请选择: " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) logs_app ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选择${RESET}" ;;
    esac
}

check_env
while true; do
    menu
    read -p "按回车键返回菜单..." enter
done