#!/bin/bash
# ========================================
# Lsky-Pro 一键管理脚本 (Docker Compose, 无数据库版)
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
RED="\033[31m"
APP_NAME="lsky-pro"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function menu() {
    clear
    echo -e "${GREEN}=== Lsky-Pro 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 重启${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) view_logs ;;
        5) restart_app ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}"; sleep 1; menu ;;
    esac
}

function restart_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose restart
    echo -e "${GREEN}✅ Lsky-Pro 已重启${RESET}"
    read -p "按回车返回菜单..."
    menu
}


function install_app() {
    read -p "请输入 Web 端口 [默认:7791]: " input_port
    PORT=${input_port:-7791}

    mkdir -p "$APP_DIR/data/html"

    # 保存配置
    cat > "$CONFIG_FILE" <<EOF
PORT=$PORT
EOF

    # 生成 compose
    cat > "$COMPOSE_FILE" <<EOF
services:
  lsky-pro:
    image: dko0/lsky-pro:latest
    container_name: lsky-pro
    restart: always
    ports:
      - "127.0.0.1:${PORT}:80"
    volumes:
      - ./data/html:/var/www/html
EOF

    cd "$APP_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ Lsky-Pro (SQLite) 已启动${RESET}"
    echo -e "${GREEN}🌐 访问地址: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ Lsky-Pro 已更新${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ Lsky-Pro 已卸载并清理数据${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f lsky-pro
    read -p "按回车返回菜单..."
    menu
}

menu
