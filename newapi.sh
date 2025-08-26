#!/bin/bash
set -e

# 颜色
GREEN="\033[32m"
RESET="\033[0m"

# 固定目录
BASE_DIR="/opt/newapi"
DATA_DIR="$BASE_DIR/data"

# MySQL 配置
MYSQL_CONTAINER="newapi-mysql"
MYSQL_ROOT="root"
MYSQL_ROOT_PASSWORD="OneAPI@justsong"
MYSQL_USER="oneapi"
MYSQL_PASSWORD="123456"
MYSQL_DB="oneapi"

# API 配置
API_CONTAINER="new-api"
API_IMAGE="calciumion/new-api:latest"
API_PORT=3000
SESSION_SECRET_FILE="$BASE_DIR/session_secret.txt"

mkdir -p "$DATA_DIR/mysql"

pause() {
    read -rp "按回车键继续..."
}

get_ip() {
    ip addr show | awk '/inet / && !/127.0.0.1/ {sub(/\/.*/,"",$2); print $2; exit}'
}

generate_secret() {
    if [ ! -f "$SESSION_SECRET_FILE" ]; then
        SESSION_SECRET=$(head -c 32 /dev/urandom | base64 | tr -d "=+/")
        echo "$SESSION_SECRET" > "$SESSION_SECRET_FILE"
        echo -e "${GREEN}生成随机 SESSION_SECRET: $SESSION_SECRET${RESET}"
    else
        SESSION_SECRET=$(cat "$SESSION_SECRET_FILE")
    fi
}

wait_mysql() {
    echo -e "${GREEN}等待 MySQL 完全启动...${RESET}"
    until docker exec $MYSQL_CONTAINER mysqladmin ping -h "127.0.0.1" --silent; do
        sleep 2
    done
    echo -e "${GREEN}MySQL 已就绪${RESET}"
}

deploy_mysql() {
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${MYSQL_CONTAINER}\$"; then
        echo -e "${GREEN}检测到 MySQL 容器已存在，跳过部署${RESET}"
        docker start $MYSQL_CONTAINER
        wait_mysql
    else
        echo -e "${GREEN}正在部署 MySQL 容器...${RESET}"
        docker run -d --name $MYSQL_CONTAINER \
            --restart always \
            -p 3306:3306 \
            -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
            -e MYSQL_USER="$MYSQL_USER" \
            -e MYSQL_PASSWORD="$MYSQL_PASSWORD" \
            -e MYSQL_DATABASE="$MYSQL_DB" \
            -v "$DATA_DIR/mysql":/var/lib/mysql \
            mysql:9.0.1
        wait_mysql
        echo -e "${GREEN}MySQL 容器已启动并就绪${RESET}"
    fi
}

deploy_api() {
    read -rp "请输入 API 端口（默认 3000）: " input_port
    API_PORT=${input_port:-3000}

    generate_secret

    echo -e "${GREEN}正在部署 New API 容器...${RESET}"
    docker run -d --name $API_CONTAINER \
        --restart always \
        -p $API_PORT:3000 \
        -e TZ=Asia/Shanghai \
        -e SQL_DSN="${MYSQL_USER}:${MYSQL_PASSWORD}@tcp(${MYSQL_CONTAINER}:3306)/${MYSQL_DB}" \
        -e SESSION_SECRET="$SESSION_SECRET" \
        -v "$DATA_DIR":/data \
        $API_IMAGE
    echo -e "${GREEN}New API 容器已启动${RESET}"
}

update_api() {
    echo -e "${GREEN}拉取最新镜像并重启容器...${RESET}"
    docker pull $API_IMAGE
    docker stop $API_CONTAINER || true
    docker rm $API_CONTAINER || true
    deploy_api
    echo -e "${GREEN}更新完成${RESET}"
}

show_info() {
    IP=$(get_ip)
    echo -e "${GREEN}访问地址: http://$IP:$API_PORT${RESET}"
}

menu() {
    while true; do
        echo -e "${GREEN}================ New API 管理菜单 ================${RESET}"
        echo -e "${GREEN}1. 部署 MySQL（检测已存在）${RESET}"
        echo -e "${GREEN}2. 部署 New API（可自定义端口）${RESET}"
        echo -e "${GREEN}3. 更新 API 镜像并重启${RESET}"
        echo -e "${GREEN}4. 显示访问地址${RESET}"
        echo -e "${GREEN}0. 退出${RESET}"
        read -rp "请选择操作: " choice
        case $choice in
            1) deploy_mysql; pause ;;
            2) deploy_api; pause ;;
            3) update_api; pause ;;
            4) show_info; pause ;;
            0) exit 0 ;;
            *) echo -e "${GREEN}无效选项${RESET}";;
        esac
    done
}

menu
