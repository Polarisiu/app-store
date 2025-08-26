#!/bin/bash
set -e

# ================== 配置 ==================
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"
DEFAULT_CORE_PORT=3000
CORE_CONTAINER="moontv-core"
KV_CONTAINER="moontv-kvrocks"
IMAGE_CORE="ghcr.io/moontechlab/lunatv:latest"
IMAGE_KV="apache/kvrocks"
NETWORK="moontv-network"
VOLUME="kvrocks-data"

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 公共函数 ==================
get_ip() {
    ip addr show | awk '/inet / && !/127.0.0.1/ {print $2}' | cut -d/ -f1 | head -n1
}

pause() {
    echo
    read -p "按回车返回菜单..."
}

# ================== 生成 docker-compose.yml ==================
generate_compose() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        cat > $COMPOSE_FILE <<'EOF'
version: '3.8'

services:
  moontv-core:
    image: ${IMAGE_CORE}
    container_name: ${CORE_CONTAINER}
    restart: on-failure
    ports:
      - "${MOONTV_CORE_PORT:-3000}:3000"
    environment:
      - USERNAME=admin
      - PASSWORD=admin_password
      - NEXT_PUBLIC_STORAGE_TYPE=kvrocks
      - KVROCKS_URL=redis://${KV_CONTAINER}:6666
      - AUTH_TOKEN=${MOONTV_AUTH_TOKEN}
    networks:
      - ${NETWORK}
    depends_on:
      - ${KV_CONTAINER}

  moontv-kvrocks:
    image: ${IMAGE_KV}
    container_name: ${KV_CONTAINER}
    restart: unless-stopped
    volumes:
      - ${VOLUME}:/var/lib/kvrocks
    networks:
      - ${NETWORK}

networks:
  ${NETWORK}:
    driver: bridge

volumes:
  ${VOLUME}:
EOF
        echo -e "${GREEN}docker-compose.yml 已生成${RESET}"
    fi
}

# ================== 功能函数 ==================
deploy() {
    read -p "请输入 MoonTV Core 映射端口(默认:3000): " port
    port=${port:-3000}

    read -p "请输入 AUTH_TOKEN: " auth_token
    auth_token=${auth_token:-"授权码"}

    cat > $ENV_FILE <<EOF
MOONTV_CORE_PORT=${port}
MOONTV_AUTH_TOKEN=${auth_token}
EOF

    docker-compose -f $COMPOSE_FILE up -d
    local ip=$(get_ip)
    echo -e "${GREEN}MoonTV 已部署完成！访问: http://${ip}:${port}${RESET}"
    pause
}

start() { docker-compose -f $COMPOSE_FILE start && echo -e "${GREEN}MoonTV 已启动${RESET}"; pause; }
stop() { docker-compose -f $COMPOSE_FILE stop && echo -e "${GREEN}MoonTV 已停止${RESET}"; pause; }
restart() { docker-compose -f $COMPOSE_FILE restart && echo -e "${GREEN}MoonTV 已重启${RESET}"; pause; }
status() { docker-compose -f $COMPOSE_FILE ps; pause; }
logs_core() { docker logs -f $CORE_CONTAINER; pause; }
logs_kv() { docker logs -f $KV_CONTAINER; pause; }

remove() {
    echo -e "${GREEN}!!! 删除操作 !!!${RESET}"
    read -p "是否同时删除 kvrocks 数据卷？(y/n): " c
    docker-compose -f $COMPOSE_FILE down
    if [ "$c" = "y" ]; then
        docker volume rm $VOLUME 2>/dev/null || true
        echo -e "${GREEN}MoonTV 容器和数据已删除${RESET}"
    else
        echo -e "${GREEN}MoonTV 容器已删除，数据已保留${RESET}"
    fi
    pause
}

update() {
    echo -e "${GREEN}>>> 拉取最新镜像并重启 MoonTV...${RESET}"
    docker-compose -f $COMPOSE_FILE pull
    docker-compose -f $COMPOSE_FILE up -d
    local ip=$(get_ip)
    local port=$(grep MOONTV_CORE_PORT $ENV_FILE | cut -d= -f2)
    echo -e "${GREEN}MoonTV 已更新完成！访问: http://${ip}:${port}${RESET}"
    pause
}

# ================== 菜单 ==================
menu() {
    echo -e "${GREEN}========= MoonTV 服务管理 =========${RESET}"
    echo -e "${GREEN}1. 部署 MoonTV${RESET}"
    echo -e "${GREEN}2. 启动服务${RESET}"
    echo -e "${GREEN}3. 停止服务${RESET}"
    echo -e "${GREEN}4. 重启服务${RESET}"
    echo -e "${GREEN}5. 查看状态${RESET}"
    echo -e "${GREEN}6. 查看 Core 日志${RESET}"
    echo -e "${GREEN}7. 查看 KV 日志${RESET}"
    echo -e "${GREEN}8. 删除容器${RESET}"
    echo -e "${GREEN}9. 更新服务${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "==================================="
    read -p "请输入选项: " opt
    case $opt in
        1) deploy ;;
        2) start ;;
        3) stop ;;
        4) restart ;;
        5) status ;;
        6) logs_core ;;
        7) logs_kv ;;
        8) remove ;;
        9) update ;;
        0) exit 0 ;;
        *) echo "无效选项"; pause ;;
    esac
    menu
}

# ================== 主入口 ==================
generate_compose
menu
