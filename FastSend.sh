#!/bin/bash
# ========================================
# FastSend 一键管理脚本 (端口映射模式)
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="FastSend"
APP_DIR="/opt/fastsend"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

menu() {
    clear
    echo -e "${GREEN}===== FastSend 管理菜单 =====${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) view_logs ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}"; sleep 1; menu ;;
    esac
}

install_app() {
    mkdir -p "$APP_DIR"

    read -rp "请输入要绑定的端口 [默认 3000]: " port
    PORT=${port:-3000}

    cat > "$COMPOSE_FILE" <<EOF

services:
  fastsend:
    image: shouchenicu/fastsend:0.6.0
    container_name: fastsend
    restart: always
    ports:
      - "127.0.0.1:$PORT:3000"
EOF

    echo "PORT=$PORT" > "$CONFIG_FILE"

    cd "$APP_DIR" || exit
    docker compose up -d

    echo -e "${GREEN}✅ $APP_NAME 已启动${RESET}"
    echo -e "${YELLOW}🌐 本地访问地址: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

update_app() {
    cd "$APP_DIR" || { echo -e "${RED}未检测到安装目录，请先安装${RESET}"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ $APP_NAME 已更新并重启完成${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

uninstall_app() {
    cd "$APP_DIR" || { echo -e "${RED}未检测到安装目录${RESET}"; sleep 1; menu; }
    docker compose down
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ $APP_NAME 已卸载${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

view_logs() {
    docker logs -f fastsend
    read -rp "按回车返回菜单..."
    menu
}

menu
