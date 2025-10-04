#!/bin/bash
# ===========================
# Gopeed (高速下载器) 管理脚本
# ===========================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="gopeed"
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
    echo -e "${GREEN}=== Gopeed 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -rp "请选择: " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) view_logs ;;
        0) exit 0 ;;
        *) echo "无效选择"; sleep 1; menu ;;
    esac
}

install_app() {
    mkdir -p "$APP_DIR/downloads" "$APP_DIR/storage"

    read -rp "请输入访问端口 [默认 9999]: " port
    port=${port:-9999}

    read -rp "设置登录用户名 [默认 admin]: " user
    user=${user:-admin}

    read -rp "设置登录密码 [默认 123456]: " pass
    pass=${pass:-123456}

    cat > "$COMPOSE_FILE" <<EOF
services:
  gopeed:
    image: liwei2633/gopeed
    container_name: gopeed
    restart: unless-stopped
    ports:
      - "127.0.0.1:${port}:9999"
    environment:
      - GOPEED_USERNAME=${user}
      - GOPEED_PASSWORD=${pass}
    volumes:
      - $APP_DIR/downloads:/app/Downloads
      - $APP_DIR/storage:/app/storage
EOF

    cd "$APP_DIR" || exit
    docker compose up -d

    echo -e "${GREEN}✅ Gopeed 已启动${RESET}"
    echo -e "${YELLOW}本地访问地址: http://127.0.0.1:${port}${RESET}"
    echo -e "${GREEN}📂 下载目录: $APP_DIR/downloads${RESET}"
    echo -e "${GREEN}📂 存储目录: $APP_DIR/storage${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ Gopeed 已更新并重启${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ Gopeed 已卸载，数据已删除${RESET}"
    read -rp "按回车返回菜单..."
    menu
}

view_logs() {
    docker logs -f gopeed
    read -rp "按回车返回菜单..."
    menu
}

check_docker
menu
