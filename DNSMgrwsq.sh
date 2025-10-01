#!/bin/bash
# =========================================
# DNSMgr Docker 管理脚本 (无数据库版, /opt 统一目录)
# =========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_DIR="/opt/dnsmgr"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
WEB_DIR="$APP_DIR/web"
NETWORK_NAME="dnsmgr-net"

mkdir -p "$WEB_DIR"

check_port() {
    local port=$1
    if lsof -i:"$port" &>/dev/null; then
        return 1
    else
        return 0
    fi
}

generate_docker_compose() {
    local web_port="$1"
    cat > "$COMPOSE_FILE" <<EOF
services:
  dnsmgr-web:
    container_name: dnsmgr-web
    stdin_open: true
    tty: true
    ports:
      - 127.0.0.1:${web_port}:80
    volumes:
      - ./web:/app/www
    image: netcccyun/dnsmgr
    networks:
      - $NETWORK_NAME

networks:
  $NETWORK_NAME:
    driver: bridge
EOF
}

start_all() {
    cd "$APP_DIR"
    docker compose -f "$COMPOSE_FILE" up -d
}

stop_all() {
    cd "$APP_DIR"
    docker compose -f "$COMPOSE_FILE" down
}

update_services() {
    cd "$APP_DIR"
    docker compose -f "$COMPOSE_FILE" pull
    docker compose -f "$COMPOSE_FILE" up -d
}

uninstall() {
    cd "$APP_DIR" || exit
    # 停止服务并删除容器
    docker compose down -v
    docker rm -f dnsmgr-web 2>/dev/null || true
    docker network rm $NETWORK_NAME 2>/dev/null || true
    docker rmi netcccyun/dnsmgr 2>/dev/null || true

    # 删除整个安装目录（包括 web 文件）
    rm -rf "$APP_DIR"

    echo -e "${GREEN}✅ DNSMgr 已卸载，数据已删除${RESET}"

}


show_info() {
    local web_port="$1"
    echo -e "${GREEN}==== 安装完成信息 ====${RESET}"
    echo -e "${YELLOW}访问 dnsmgr-web:${RESET} http://127.0.0.1:$web_port"
    echo -e "${GREEN}📂 数据目录: $APP_DIR${RESET}"
}

menu() {
    while true; do
        clear
        echo -e "${GREEN}==== DNSMgr Docker 管理菜单====${RESET}"
        echo -e "${GREEN}1) 安装启动${RESET}"
        echo -e "${GREEN}2) 启动服务${RESET}"
        echo -e "${GREEN}3) 停止服务${RESET}"
        echo -e "${GREEN}4) 更新服务${RESET}"
        echo -e "${GREEN}5) 卸载${RESET}"
        echo -e "${GREEN}0) 退出${RESET}"
        read -p "请输入操作编号: " choice
        case "$choice" in
            1)
                while true; do
                    read -p "请输入 dnsmgr-web 映射端口 (默认 8081): " web_port
                    web_port=${web_port:-8081}
                    if check_port "$web_port"; then
                        break
                    else
                        echo -e "${RED}端口 $web_port 已被占用，请重新输入！${RESET}"
                    fi
                done
                generate_docker_compose "$web_port"
                start_all
                show_info "$web_port"
                ;;
            2) start_all; echo -e "${GREEN}服务已启动！${RESET}" ;;
            3) stop_all ;;
            4) update_services ;;
            5) uninstall ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选项！${RESET}" ;;
        esac
    done
}

menu
