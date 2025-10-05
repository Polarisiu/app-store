#!/bin/bash
# ========================================
# VPS Value Calculator 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
YELLOW="\033[33m"
RED="\033[31m"
APP_NAME="vps-value-calculator"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function menu() {
    clear
    echo -e "${GREEN}=== VPS Value Calculator 管理菜单 ===${RESET}"
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

function install_app() {
    read -p "请输入访问端口 [默认:8280]: " input_port
    PORT=${input_port:-8280}

    mkdir -p "$APP_DIR/data" "$APP_DIR/static/images"

    cat > "$COMPOSE_FILE" <<EOF

services:
  $APP_NAME:
    image: ghcr.io/podcctv/vps-value-calculator:latest
    container_name: $APP_NAME
    restart: unless-stopped
    ports:
      - "127.0.0.1:$PORT:8280"
    volumes:
      - $APP_DIR/data:/app/data
      - $APP_DIR/static/images:/app/static/images
EOF

    echo "PORT=$PORT" > "$CONFIG_FILE"

    cd "$APP_DIR"
    docker compose up -d

    # 获取公网IP
    get_ip() {
        curl -s ifconfig.me || curl -s ip.sb || hostname -I | awk '{print $1}'
    }

    echo -e "${GREEN}✅ $APP_NAME 已启动${RESET}"
    echo -e "${YELLOW}🌐 本机访问地址: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/data${RESET}"
    echo -e "${GREEN}📂 图片目录: $APP_DIR/static/images${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ $APP_NAME 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ $APP_NAME 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f $APP_NAME
    read -p "按回车返回菜单..."
    menu
}

menu
