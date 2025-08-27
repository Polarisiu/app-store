#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_URL_FILE=".app_url"
PORT_FILE=".port"
DOCKER_COMPOSE_FILE="docker-compose.yml"
DEFAULT_PORT=8000

# ================== 工具函数 ==================
check_prerequisites() {
    command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker 未安装，请先安装 Docker${RESET}"; exit 1; }
    command -v docker-compose >/dev/null 2>&1 || { echo -e "${RED}Docker Compose 未安装，请先安装${RESET}"; exit 1; }
}

create_2fauth_dir() {
    if [ ! -d "2fauth" ]; then
        mkdir 2fauth
        chown 1000:1000 2fauth
        chmod 700 2fauth
        echo -e "${GREEN}2fauth 目录已创建并设置权限${RESET}"
    else
        echo -e "${YELLOW}2fauth 目录已存在，跳过创建${RESET}"
    fi
}

set_app_url_and_port() {
    read -rp "$(echo -e "${GREEN}请输入访问端口 (默认 $DEFAULT_PORT): ${RESET}")" PORT
    PORT=${PORT:-$DEFAULT_PORT}
    read -rp "$(echo -e "${GREEN}请输入 APP_URL (例如 http://192.168.1.10:$PORT): ${RESET}")" APP_URL
    APP_URL=${APP_URL:-"http://127.0.0.1:$PORT"}
    echo "$APP_URL" > "$APP_URL_FILE"
    echo "$PORT" > "$PORT_FILE"
    echo -e "${GREEN}APP_URL 已保存: $APP_URL${RESET}"
}

generate_compose_file() {
    if [ -f "$APP_URL_FILE" ] && [ -f "$PORT_FILE" ]; then
        APP_URL=$(cat "$APP_URL_FILE")
        PORT=$(cat "$PORT_FILE")
    else
        echo -e "${RED}未设置 APP_URL 或端口，请先设置${RESET}"
        return
    fi

    cat > $DOCKER_COMPOSE_FILE <<EOF
version: '3.8'

services:
  2fauth:
    image: 2fauth/2fauth
    container_name: 2fauth
    volumes:
      - ./2fauth:/2fauth
    ports:
      - ${PORT}:8000/tcp
    environment:
      - APP_URL=$APP_URL
EOF

    echo -e "${GREEN}docker-compose.yml 已生成${RESET}"
}

install_service() {
    create_2fauth_dir
    set_app_url_and_port
    generate_compose_file
    docker-compose up -d
    echo -e "${GREEN}2fauth 安装并启动完成，访问: $(cat $APP_URL_FILE)${RESET}"
}

update_service() {
    echo -e "${GREEN}拉取最新镜像并重启服务...${RESET}"
    docker-compose pull
    docker-compose up -d
    echo -e "${GREEN}更新完成${RESET}"
}

uninstall_service() {
    docker-compose down
    echo -e "${YELLOW}容器已停止${RESET}"
    read -rp "$(echo -e "${GREEN}是否删除数据目录和配置文件？(y/n): ${RESET}")" confirm
    if [[ $confirm =~ ^[Yy]$ ]]; then
        rm -rf 2fauth docker-compose.yml $APP_URL_FILE $PORT_FILE
        echo -e "${YELLOW}已删除数据和配置文件${RESET}"
    fi
}

view_logs() {
    docker-compose logs -f
}

show_menu() {
    clear
    echo -e "${GREEN}==== 2fauth Docker 管理脚本 ====${RESET}"
    echo -e "${GREEN}1) 安装部署${RESET}"
    echo -e "${GREEN}2) 更新服务${RESET}"
    echo -e "${GREEN}3) 卸载服务${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 退出${RESET}"
    echo -e "${GREEN}==================================${RESET}"
}

# ================== 主循环 ==================
check_prerequisites

while true; do
    show_menu
    read -rp "$(echo -e "${GREEN}请选择操作: ${RESET}")" choice
    case $choice in
        1) install_service; read -rp "$(echo -e "${GREEN}按回车返回菜单...${RESET}")" ;;
        2) update_service; read -rp "$(echo -e "${GREEN}按回车返回菜单...${RESET}")" ;;
        3) uninstall_service; read -rp "$(echo -e "${GREEN}按回车返回菜单...${RESET}")" ;;
        4) view_logs ;;
        5) echo -e "${GREEN}退出${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}"; read -rp "$(echo -e "${GREEN}按回车返回菜单...${RESET}")" ;;
    esac
done
