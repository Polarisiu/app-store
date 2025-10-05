#!/bin/bash
# ======================================
# Moments 一键管理脚本 (端口映射模式)
# ======================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="moments"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}未检测到 Docker，请先安装 Docker${RESET}"
        exit 1
    fi
}

menu() {
    clear
    echo -e "${GREEN}=== Moments 管理菜单 ===${RESET}"
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
    mkdir -p "$APP_DIR/data"

    read -rp "请输入要绑定的端口 [默认 3000]: " port
    port=${port:-3000}
    read -rp "请输入JWT_KEY(例如 3c100a79-5a2c-4a77-a392-8ca34daeba46): " JWT_KEY
    export JWT_KEY

    cat > "$COMPOSE_FILE" <<EOF
services:
  moments:
    image: kingwrcy/moments:latest
    container_name: moments
    restart: always
    environment:
      PORT: 3000
      JWT_KEY: $JWT_KEY
    ports:
      - "127.0.0.1:${port}:3000"
    volumes:
      - $APP_DIR/data:/app/data
EOF

    cd "$APP_DIR" || exit
    docker compose up -d

    echo -e "${GREEN}✅ Moments 已启动${RESET}"
    echo -e "${YELLOW}本地访问地址: http://127.0.0.1:${port}${RESET}"
    echo -e "${GREEN} 账号/密码: admin/a123456${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/data${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ Moments 已更新并重启完成${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ Moments 已卸载，数据已删除${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

view_logs() {
    docker logs -f moments
    read -rp "按回车返回菜单..."
    menu
}

check_docker
menu
