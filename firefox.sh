#!/bin/bash
# ========================================
# Firefox 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="firefox"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"

function menu() {
    clear
    echo -e "${GREEN}=== Firefox 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 重启${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -rp "请选择: " choice
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
    mkdir -p "$APP_DIR"

    read -rp "请输入 Web 端口 [默认:3000]: " input_web
    WEB_PORT=${input_web:-3000}

    read -rp "请输入 VNC 端口 [默认:3001]: " input_vnc
    VNC_PORT=${input_vnc:-3001}

    read -rp "请输入登录用户名 [默认:admin]: " input_user
    CUSTOM_USER=${input_user:-admin}

    read -rp "请输入登录密码 [默认:admin123]: " input_pass
    PASSWORD=${input_pass:-admin123}

    cat > "$COMPOSE_FILE" <<EOF
services:
  firefox:
    image: lscr.io/linuxserver/firefox:latest
    container_name: firefox
    restart: unless-stopped
    security_opt:
      - seccomp=unconfined
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
      - DOCKER_MODS=linuxserver/mods:universal-package-install
      - INSTALL_PACKAGES=fonts-noto-cjk
      - LC_ALL=zh_CN.UTF-8
      - CUSTOM_USER=$CUSTOM_USER
      - PASSWORD=$PASSWORD
    ports:
      - "127.0.0.1:$WEB_PORT:3000"
      - "127.0.0.1:$VNC_PORT:3001"
    volumes:
      - $APP_DIR/config:/config
    shm_size: 1gb
EOF

    echo -e "WEB_PORT=$WEB_PORT\nVNC_PORT=$VNC_PORT\nCUSTOM_USER=$CUSTOM_USER\nPASSWORD=$PASSWORD" > "$CONFIG_FILE"

    cd "$APP_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ Firefox 已启动${RESET}"
    echo -e "${YELLOW}🌐 Web UI 地址: http://127.0.0.1:$WEB_PORT${RESET}"
    echo -e "${YELLOW}🌐 VNC 地址: http://127.0.0.1:$VNC_PORT${RESET}"
    echo -e "${GREEN}        账号: $CUSTOM_USER${RESET}"
    echo -e "${GREEN}        密码: $PASSWORD${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/config${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ Firefox 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ Firefox 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f firefox
    read -p "按回车返回菜单..."
    menu
}

function restart_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose restart
    echo -e "${GREEN}✅ Firefox 已重启${RESET}"
    read -p "按回车返回菜单..."
    menu
}

menu
