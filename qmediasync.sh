#!/bin/bash
# ========================================
# QMediaSync 一键管理脚本 (端口映射模式)
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="QMediaSync"
APP_DIR="/opt/qmediasync"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

menu() {
    clear
    echo -e "${GREEN}===== QMediaSync 管理菜单 =====${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 重启${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -rp "请输入编号: " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) view_logs ;;
        5) restart_app ;;
        0) exit 0 ;;
        *) echo -e "${RED}❌ 无效选择${RESET}"; sleep 1; menu ;;
    esac
}

install_app() {
    mkdir -p "$APP_DIR/config" "$APP_DIR/media"

    read -rp "请输入主端口 [默认 12333]: " port_main
    PORT_MAIN=${port_main:-12333}

    read -rp "请输入 Emby http端口 [默认 8095]: " port_web
    PORT_WEB=${port_web:-8095}

    read -rp "请输入 Emby https端口 [默认 8094]: " port_api
    PORT_API=${port_api:-8094}

    cat > "$COMPOSE_FILE" <<EOF

services:
  qmediasync:
    image: qicfan/qmediasync:latest
    container_name: qmediasync
    restart: unless-stopped
    ports:
      - "127.0.0.1:$PORT_MAIN:12333"
      - "127.0.0.1:$PORT_WEB:8095"
      - "127.0.0.1:$PORT_API:8094"
    volumes:
      - ./config:/app/config
      - ./media:/media
    environment:
      - TZ=Asia/Shanghai
EOF

    echo "PORT_MAIN=$PORT_MAIN" > "$CONFIG_FILE"
    echo "PORT_WEB=$PORT_WEB" >> "$CONFIG_FILE"
    echo "PORT_API=$PORT_API" >> "$CONFIG_FILE"

    cd "$APP_DIR" || exit
    docker compose up -d

    echo -e "${GREEN}✅ $APP_NAME 已启动${RESET}"
    echo -e "${GREEN}🌐 访问地址: 127.0.0.1:$PORT_MAIN${RESET}"
    echo -e "${GREEN}🌐 Emby http端口: $PORT_WEB${RESET}"
    echo -e "${GREEN}🌐 Emby https端口:$PORT_API${RESET}"
    echo -e "${GREEN}🌐 账户/密码: admin/admin123${RESET}"
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
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ $APP_NAME 已卸载，数据已删除${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

view_logs() {
    docker logs -f qmediasync
    read -rp "按回车返回菜单..."
    menu
}

restart_app() {
    cd "$APP_DIR" || { echo -e "${RED}未检测到安装目录${RESET}"; sleep 1; menu; }
    docker compose restart
    echo -e "${GREEN}✅ $APP_NAME 已重启${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

menu
