#!/bin/bash
set -e

# ================== 配置 ==================
SERVICE="zurl"
IMAGE="helloz/zurl"
DEFAULT_PORT=3080
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 公共函数 ==================
get_ip() {
    ip addr show | awk '/inet / && !/127.0.0.1/ {print $2}' | cut -d/ -f1 | head -n1
}

init_compose() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        cat > $COMPOSE_FILE <<EOF
version: '3.8'

services:
  ${SERVICE}:
    container_name: ${SERVICE}
    image: ${IMAGE}
    ports:
      - "\${ZURL_PORT:-${DEFAULT_PORT}}:3080"
    restart: always
    volumes:
      - ./data:/opt/zurl/app/data
EOF
        echo -e "${GREEN}已生成 docker-compose.yml 模版${RESET}"
    fi
}

# ================== 功能函数 ==================
deploy() {
    read -p "请输入映射端口(默认:${DEFAULT_PORT}): " port
    port=${port:-$DEFAULT_PORT}
    echo "ZURL_PORT=${port}" > $ENV_FILE

    docker-compose -f $COMPOSE_FILE up -d
    local ip=$(get_ip)
    echo -e "${GREEN}zurl 已部署完成，访问: http://${ip}:${port}${RESET}"
    echo -e "${GREEN}根据提示完成初始化即可 🎉${RESET}"
}

start() { docker-compose -f $COMPOSE_FILE start && echo -e "${GREEN}zurl 已启动${RESET}"; }
stop() { docker-compose -f $COMPOSE_FILE stop && echo -e "${GREEN}zurl 已停止${RESET}"; }
restart() { docker-compose -f $COMPOSE_FILE restart && echo -e "${GREEN}zurl 已重启${RESET}"; }
status() { docker-compose -f $COMPOSE_FILE ps; }
logs() { docker-compose -f $COMPOSE_FILE logs -f $SERVICE; }
enter() { docker exec -it $SERVICE /bin/sh; }

remove() {
    echo -e "${GREEN}!!! 删除操作 !!!${RESET}"
    read -p "是否同时删除数据目录 ./data ？(y/n): " c
    docker-compose -f $COMPOSE_FILE down
    if [ "$c" = "y" ]; then
        rm -rf ./data
        echo -e "${GREEN}zurl 容器和数据已删除${RESET}"
    else
        echo -e "${GREEN}zurl 容器已删除，数据已保留${RESET}"
    fi
}

update() {
    echo -e "${GREEN}>>> 正在拉取最新镜像...${RESET}"
    docker-compose -f $COMPOSE_FILE pull
    docker-compose -f $COMPOSE_FILE up -d
    local ip=$(get_ip)
    local port=$(grep ZURL_PORT $ENV_FILE | cut -d= -f2)
    echo -e "${GREEN}zurl 已更新完成，访问: http://${ip}:${port}${RESET}"
}

# ================== 菜单 ==================
menu() {
    echo -e "${GREEN}========= Zurl 服务管理 =========${RESET}"
    echo -e "${GREEN}1. 部署 Zurl${RESET}"
    echo -e "${GREEN}2. 启动${RESET}"
    echo -e "${GREEN}3. 停止${RESET}"
    echo -e "${GREEN}4. 重启${RESET}"
    echo -e "${GREEN}5. 查看状态${RESET}"
    echo -e "${GREEN}6. 查看日志${RESET}"
    echo -e "${GREEN}7. 进入容器${RESET}"
    echo -e "${GREEN}8. 删除容器${RESET}"
    echo -e "${GREEN}9. 更新服务${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "================================"
    read -p "请输入选项: " opt
    case $opt in
        1) deploy ;;
        2) start ;;
        3) stop ;;
        4) restart ;;
        5) status ;;
        6) logs ;;
        7) enter ;;
        8) remove ;;
        9) update ;;
        0) exit 0 ;;
        *) echo "无效选项" ;;
    esac
    sleep 2
    menu
}

# ================== 主入口 ==================
init_compose
menu
