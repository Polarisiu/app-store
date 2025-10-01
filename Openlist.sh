\#!/bin/bash
# ========================================
# OpenList 一键管理脚本
# 支持自定义端口 & 管理员密码
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
APP_NAME="openlist"
COMPOSE_DIR="/opt/openlist"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

# 获取公网IP
function get_ip() {
    curl -s ifconfig.me || curl -s ip.sb || echo "your-ip"
}

function menu() {
    clear
    echo -e "${GREEN}=== OpenList 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "请选择: " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) view_logs ;;
        0) exit 0 ;;
        *) echo "无效选择"; sleep 1; menu ;;
    esac
}

function install_app() {
    read -p "请输入映射端口 [默认:5244]: " input_port
    PORT=${input_port:-5244}

    read -p "请输入管理员密码 [默认:adminadmin]: " input_pwd
    ADMIN_PWD=${input_pwd:-adminadmin}

    mkdir -p "$COMPOSE_DIR/data"

    cat > "$COMPOSE_FILE" <<EOF

services:
  openlist:
    image: openlistteam/openlist:latest
    container_name: openlist
    user: "0:0"
    restart: unless-stopped
    ports:
      - "127.0.0.1:$PORT:5244"
    environment:
      - UMASK=022
      - OPENLIST_ADMIN_PASSWORD=${ADMIN_PWD}
    volumes:
      - ${COMPOSE_DIR}/data:/opt/openlist/data
EOF

    cd "$COMPOSE_DIR"
    docker compose up -d
    echo -e "${GREEN}✅ OpenList 已启动${RESET}"
    echo -e "${GREEN}🌐 访问地址: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}👤 管理员密码: $ADMIN_PWD${RESET}"
    echo -e "${GREEN}📂 数据目录: $COMPOSE_DIR/data${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$COMPOSE_DIR" || exit
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ OpenList 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$COMPOSE_DIR" || exit
    docker compose down -v
    rm -rf "$COMPOSE_DIR"
    echo -e "${GREEN}✅ OpenList 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f openlist
    read -p "按回车返回菜单..."
    menu
}

menu
