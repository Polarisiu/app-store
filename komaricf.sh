#!/bin/bash
# ============================================
# Komari 管理脚本（菜单版）
# 功能: 安装/更新/卸载/日志
# ============================================

set -e

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

COMPOSE_FILE="/opt/komari/docker-compose.yml"
DATA_DIR="/opt/komari/data"
CONTAINER_NAME="komari"
PORT=25774

menu() {
    clear
    echo -e "${GREEN}=== Komari 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载i${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 重启${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice
    case $choice in
        1) install_komari ;;
        2) update_komari ;;
        3) uninstall_komari ;;
        4) view_logs ;;
        5) restart_komari ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择！${RESET}" && sleep 1 && menu ;;
    esac
}

restart_komari() {
    echo -e "${GREEN}=== 重启 Komari ===${RESET}"
    docker compose -f "$COMPOSE_FILE" restart
    echo -e "${GREEN}✅ Komari 已重启${RESET}"
    read -p "按回车返回菜单..." && menu
}


install_komari() {
    echo -e "${GREEN}=== 开始安装 Komari ===${RESET}"

    mkdir -p "$DATA_DIR"

    read -p "请输入管理员用户名 (默认: admin): " ADMIN_USERNAME
    ADMIN_USERNAME=${ADMIN_USERNAME:-admin}

    read -p "请输入管理员密码 (默认: admin123): " ADMIN_PASSWORD
    ADMIN_PASSWORD=${ADMIN_PASSWORD:-admin123}

    # Cloudflared 默认启用 true
    KOMARI_ENABLE_CLOUDFLARED="true"
    echo -e "${GREEN}Cloudflared 已默认启用${RESET}"
    read -p "请输入 Cloudflared Token: " KOMARI_CLOUDFLARED_TOKEN

    cat > "$COMPOSE_FILE" <<EOF
services:
  komari:
    image: ghcr.io/komari-monitor/komari:latest
    container_name: $CONTAINER_NAME
    ports:
      - "${PORT}:${PORT}"
    volumes:
      - $DATA_DIR:/app/data
    environment:
      ADMIN_USERNAME: "$ADMIN_USERNAME"
      ADMIN_PASSWORD: "$ADMIN_PASSWORD"
      KOMARI_ENABLE_CLOUDFLARED: "$KOMARI_ENABLE_CLOUDFLARED"
      KOMARI_CLOUDFLARED_TOKEN: "$KOMARI_CLOUDFLARED_TOKEN"
      PORT: "$PORT"
    restart: unless-stopped
EOF

    docker compose -f "$COMPOSE_FILE" up -d
    echo -e "${GREEN}✅ 部署完成！访问地址: http://$(curl -s https://api.ipify.org):$PORT${RESET}"
    echo -e "${GREEN}用户名: $ADMIN_USERNAME  密码: $ADMIN_PASSWORD${RESET}"
    echo -e "${GREEN}📂 数据目录: /opt/komari${RESET}"
    read -p "按回车返回菜单..." && menu
}

update_komari() {
    echo -e "${GREEN}=== 更新 Komari ===${RESET}"
    docker compose -f "$COMPOSE_FILE" pull
    docker compose -f "$COMPOSE_FILE" up -d
    echo -e "${GREEN}✅ 更新完成！${RESET}"
    read -p "按回车返回菜单..." && menu
}

uninstall_komari() {
    echo -e "${RED}即将卸载 Komari，并删除相关数据！${RESET}"
    read -p "确认卸载? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        docker compose -f "$COMPOSE_FILE" down -v
        rm -rf "/opt/komari"
        echo -e "${GREEN}✅ 卸载完成${RESET}"
    else
        echo -e "${GREEN}已取消${RESET}"
    fi
    read -p "按回车返回菜单..." && menu
}

view_logs() {
    echo -e "${GREEN}=== 查看 Komari 日志 ===${RESET}"
    docker logs -f $CONTAINER_NAME
    read -p "按回车返回菜单..." && menu
}

menu
