#!/bin/bash
# Pairdrop 管理脚本 (绿色菜单版)

SERVICE_NAME="pairdrop"
INSTALL_DIR="/opt/$SERVICE_NAME"
COMPOSE_FILE="$INSTALL_DIR/docker-compose.yml"

# 颜色
GREEN="\e[32m"
RESET="\e[0m"

install() {
    echo -e "${GREEN}>>> 开始安装 Pairdrop 服务...${RESET}"

    read -p "请输入映射端口 (默认 3000): " PORT
    PORT=${PORT:-3000}

    read -p "请输入时区 (默认 Asia/Shanghai): " TZ
    TZ=${TZ:-Asia/Shanghai}

    mkdir -p "$INSTALL_DIR/config"

    cat > $COMPOSE_FILE <<EOF

services:
  pairdrop:
    image: lscr.io/linuxserver/pairdrop:latest
    container_name: $SERVICE_NAME
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=$TZ
      - WS_FALLBACK=false
      - RATE_LIMIT=false
      - RTC_CONFIG=false
      - DEBUG_MODE=false
    ports:
      - "127.0.0.1:$PORT:3000"
    volumes:
      - ./config:/config
EOF

    cd "$INSTALL_DIR"
    docker compose up -d

    # 获取服务器外网IP
    IP=$(curl -s ifconfig.me)
    if [ -z "$IP" ]; then
        IP=$(hostname -I | awk '{print $1}')
    fi

    echo -e "${GREEN}>>> Pairdrop 服务已安装并运行在: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}📂 数据目录: $INSTALL_DIR ${RESET}"
    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
    menu
}


start() {
    cd "$INSTALL_DIR" && docker compose up -d
    echo -e "${GREEN}>>> Pairdrop 服务已启动${RESET}"
    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
    menu
}

stop() {
    cd "$INSTALL_DIR" && docker compose down
    echo -e "${GREEN}>>> Pairdrop 服务已停止${RESET}"
    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
    menu
}

restart() {
    stop
    start
}

update() {
    cd "$INSTALL_DIR"
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}>>> Pairdrop 服务已更新${RESET}"
    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
    menu
}

uninstall() {
    cd "$INSTALL_DIR" || exit
    docker compose down -v
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}✅ Pairdrop已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}


menu() {
    clear
    echo -e "${GREEN}======================${RESET}"
    echo -e "${GREEN} Pairdrop 管理菜单${RESET}"
    echo -e "${GREEN}======================${RESET}"
    echo -e "${GREEN}1. 安装${RESET}"
    echo -e "${GREEN}2. 启动${RESET}"
    echo -e "${GREEN}3. 停止${RESET}"
    echo -e "${GREEN}4. 重启${RESET}"
    echo -e "${GREEN}5. 更新${RESET}"
    echo -e "${GREEN}6. 卸载${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -ne "${GREEN}请输入选项: ${RESET}"
    read CHOICE
    case $CHOICE in
        1) install ;;
        2) start ;;
        3) stop ;;
        4) restart ;;
        5) update ;;
        6) uninstall ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选项${RESET}" ; sleep 1 ; menu ;;
    esac
}

menu
