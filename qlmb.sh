#!/bin/bash
# ========================================
# QingLong 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
YELLOW="\033[33m"
APP_NAME="qinglong"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function menu() {
    clear
    echo -e "${GREEN}=== QingLong 管理菜单 ===${RESET}"
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
    read -p "请输入 Web 端口 [默认:5700]: " input_port
    PORT=${input_port:-5700}

    # 创建统一文件夹
    mkdir -p "$APP_DIR/data"

    # 生成 docker-compose.yml
    cat > "$COMPOSE_FILE" <<EOF
services:
  qinglong:
    image: whyour/qinglong:latest
    container_name: qinglong
    volumes:
      - $APP_DIR/data:/ql/data
    ports:
      - "127.0.0.1:$PORT:5700"
    environment:
      QlBaseUrl: '/'
    restart: unless-stopped
EOF

    echo "PORT=$PORT" > "$CONFIG_FILE"

    cd "$APP_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ QingLong 已启动${RESET}"
    echo -e "${YELLOW}🌐本机地址: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/data${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ QingLong 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ QingLong 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f qinglong
    read -p "按回车返回菜单..."
    menu
}

menu
