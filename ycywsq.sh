#!/bin/bash
# ======================================
# ACGFaka 远程数据库一键管理脚本 (端口映射模式)
# ======================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="acgfaka"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}未检测到 Docker，请先安装 Docker${RESET}"
        exit 1
    fi
}

# 菜单
menu() {
    while true; do
        clear
        echo -e "${GREEN}=== ACGFaka 管理菜单 ===${RESET}"
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
            *) echo "无效选择"; sleep 1 ;;
        esac
    done
}

# 安装启动
install_app() {
    mkdir -p "$APP_DIR/acgfaka"

    read -rp "请输入 Web 端口 [默认 8080]: " WEB_PORT
    WEB_PORT=${WEB_PORT:-8080}

    cat > "$COMPOSE_FILE" <<EOF
services:
  acgfaka:
    image: dapiaoliang666/acgfaka
    ports:
      - "127.0.0.1:${WEB_PORT}:80"
    depends_on:
      - redis
    restart: always
    environment:
      PHP_OPCACHE_ENABLE: 1
      PHP_OPCACHE_MEMORY_CONSUMPTION: 128
      PHP_OPCACHE_MAX_ACCELERATED_FILES: 10000
      PHP_OPCACHE_REVALIDATE_FREQ: 2
      PHP_REDIS_HOST: redis
      PHP_REDIS_PORT: 6379
    volumes:
      - ./acgfaka:/var/www/html

  redis:
    image: redis:latest
    restart: always
EOF

    cd "$APP_DIR" || exit
    docker compose up -d

    echo -e "${GREEN}✅ ACGFaka 已启动${RESET}"
    echo -e "${YELLOW}本地访问地址: http://127.0.0.1:${WEB_PORT}${RESET}"
    echo -e "${GREEN}后台路径: http://127.0.0.1:$WEB_PORT/admin${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR${RESET}"
    read -rp "按回车返回菜单..."
}

# 更新
update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; return; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ ACGFaka 已更新并重启完成${RESET}"
    read -rp "按回车返回菜单..."
}

# 卸载
uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; return; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ ACGFaka 已卸载${RESET}"
    read -rp "按回车返回菜单..."
}

# 查看日志
view_logs() {
    docker logs -f acgfaka
    read -rp "按回车返回菜单..."
}

# 重启
restart_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; return; }
    docker compose restart
    echo -e "${GREEN}✅ ACGFaka 已重启完成${RESET}"
    read -rp "按回车返回菜单..."
}

# 检查 Docker 并启动菜单
check_docker
menu
