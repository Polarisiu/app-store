#!/bin/bash
# ========================================
# Vaultwarden 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
YELLOW="\033[33m"
APP_NAME="vaultwarden"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function get_ip() {
    curl -s ifconfig.me || curl -s ip.sb || echo "127.0.0.1"
}

function menu() {
    clear
    echo -e "${GREEN}=== Vaultwarden 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 重启${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "请选择: " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) view_logs ;;
        5) restart_app ;;
        0) exit 0 ;;
        *) echo "无效选择"; sleep 1; menu ;;
    esac
}

function install_app() {
    read -p "请输入 Web 端口 [默认:11001]: " input_port
    PORT=${input_port:-11001}

    read -p "请输入域名（例如 https://vaultwarden.example.com）: " DOMAIN
    read -p "允许注册新用户? (true/false) [默认:true]: " SIGNUPS_ALLOWED_INPUT
    SIGNUPS_ALLOWED=${SIGNUPS_ALLOWED_INPUT:-true}

    # 创建统一数据目录
    mkdir -p "$APP_DIR/vw-data"

    # 生成 docker-compose.yml
    cat > "$COMPOSE_FILE" <<EOF
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: always
    environment:
      DOMAIN: "$DOMAIN"
      SIGNUPS_ALLOWED: "$SIGNUPS_ALLOWED"
    volumes:
      - $APP_DIR/vw-data:/data
    ports:
      - "$PORT:80"
EOF

    # 保存配置
    cat > "$CONFIG_FILE" <<EOF
PORT=$PORT
DOMAIN=$DOMAIN
SIGNUPS_ALLOWED=$SIGNUPS_ALLOWED
EOF

    cd "$APP_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ Vaultwarden 已启动${RESET}"
    echo -e "${YELLOW}🌐 本机访问地址: http://127.0.0.1:$PORT${RESET}"
    [ -n "$DOMAIN" ] && echo -e "${GREEN}🔗 域名: $DOMAIN${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/vw-data${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ Vaultwarden 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ Vaultwarden 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f vaultwarden
    read -p "按回车返回菜单..."
    menu
}

function restart_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose restart
    echo -e "${GREEN}✅ Vaultwarden 已重启${RESET}"
    read -p "按回车返回菜单..."
    menu
}

menu
