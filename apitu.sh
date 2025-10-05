#!/bin/bash
# ========================================
# Random-Image-API 一键管理脚本
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
RED="\033[31m"
APP_NAME="random-image-api"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function menu() {
    clear
    echo -e "${GREEN}=== Random-Image-API 管理菜单 ===${RESET}"
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
    read -p "请输入 Web 端口 [默认:3007]: " input_port
    PORT=${input_port:-3007}

    read -p "请输入图床地址 [默认: https://img.ibytebox.com]: " input_url
    LSKY_API_URL=${input_url:-https://img.ibytebox.com}

    read -p "请输入图床 Token: " LSKY_TOKEN
    read -p "请输入自定义标题 [默认: 我的随机图片]: " CUSTOM_TITLE
    CUSTOM_TITLE=${CUSTOM_TITLE:-我的随机图片}

    mkdir -p "$APP_DIR/data"

    # 生成 docker-compose.yml
    cat > "$COMPOSE_FILE" <<EOF
services:
  random-image-api:
    image: libyte/random-image-api:latest
    container_name: random-image-api
    restart: unless-stopped
    ports:
      - "127.0.0.1:$PORT:3007"
    environment:
      - LSKY_API_URL=$LSKY_API_URL
      - LSKY_TOKEN=$LSKY_TOKEN
      - CUSTOM_TITLE=$CUSTOM_TITLE
    volumes:
      - $APP_DIR/data:/app/data
EOF

    echo -e "PORT=$PORT\nLSKY_API_URL=$LSKY_API_URL\nLSKY_TOKEN=$LSKY_TOKEN\nCUSTOM_TITLE=$CUSTOM_TITLE" > "$CONFIG_FILE"

    cd "$APP_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ Random-Image-API 已启动${RESET}"
    echo -e "${GREEN}🌐 Web UI 地址: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/data${RESET}"
    echo -e "${GREEN}🔑 Token: $LSKY_TOKEN${RESET}"
    echo -e "${GREEN}🌐 访问方式${RESET}"
    echo -e "${GREEN}主页预览：http://127.0.0.1:3007/  - 好看的图片页面${RESET}"
    echo -e "${GREEN}直接图片：http://127.0.0.1:3007/api  - 纯图片，刷新换图${RESET}"
    echo -e "${GREEN}JSON 数据：http://127.0.0.1:3007/?format=json  - 程序调用${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    source "$CONFIG_FILE"
    echo -e "${GREEN}✅ Random-Image-API 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ Random-Image-API 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f random-image-api
    read -p "按回车返回菜单..."
    menu
}

menu
