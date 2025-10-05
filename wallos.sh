#!/bin/bash
# ========================================
# Wallos 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
YELLOW="\033[33m"
APP_NAME="wallos"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function get_ip() {
    curl -s ifconfig.me || curl -s ip.sb || echo "your-ip"
}

function menu() {
    clear
    echo -e "${GREEN}=== Wallos 管理菜单 ===${RESET}"
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
    mkdir -p "$APP_DIR/db" "$APP_DIR/logos"

    read -p "请输入 Web 端口 [默认:8282]: " input_port
    PORT=${input_port:-8282}
    echo "PORT=$PORT" > "$CONFIG_FILE"

    cat > "$COMPOSE_FILE" <<EOF
services:
  wallos:
    container_name: wallos
    image: bellamy/wallos:latest
    ports:
       - "127.0.0.1:$PORT:80"
    environment:
      TZ: Asia/Shanghai
    volumes:
      - ./db:/var/www/html/db
      - ./logos:/var/www/html/images/uploads/logos
    restart: unless-stopped
    env_file:
      - ./config.env
EOF

    cd "$APP_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ Wallos 已启动${RESET}"
    echo -e "${YELLOW}🌐 本机访问地址: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}📂 配置目录: $APP_DIR${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到配置文件，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ Wallos 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到配置文件，请先安装"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ Wallos 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f $APP_NAME
    read -p "按回车返回菜单..."
    menu
}

menu
