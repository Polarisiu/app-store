#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# ================== 默认配置 ==================
DEFAULT_PORT=3000
DEFAULT_DATA="/opt/newapi"
MYSQL_CONTAINER="newapi-mysql"
MYSQL_ROOT_PASSWORD="123456"
MYSQL_DB="newapi"
MYSQL_USER="newapiuser"
MYSQL_PASSWORD="newapipass"
API_CONTAINER="new-api"
API_IMAGE="calciumion/new-api:latest"

# ================== 工具函数 ==================
pause() { read -rp "按回车键继续..."; }

show_ip_port() {
    IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}访问地址: ${IP}:${API_PORT}${RESET}"
}

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}请先安装 Docker${RESET}"
        exit 1
    fi
}

init_env() {
    mkdir -p "$DEFAULT_DATA"
    if [ ! -f "$DEFAULT_DATA/.env" ]; then
        cat > "$DEFAULT_DATA/.env" <<EOF
PORT=$API_PORT
MYSQL_HOST=$MYSQL_CONTAINER
MYSQL_PORT=3306
MYSQL_DB=$MYSQL_DB
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF
        echo -e "${GREEN}.env 文件已生成${RESET}"
    fi
}

start_mysql() {
    if ! docker ps -a --format '{{.Names}}' | grep -q "$MYSQL_CONTAINER"; then
        docker run -d --name $MYSQL_CONTAINER --restart always \
            -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
            -p 3306:3306 \
            mysql:8
        echo -e "${GREEN}MySQL 已启动${RESET}"
    else
        docker start $MYSQL_CONTAINER
        echo -e "${GREEN}MySQL 容器已启动${RESET}"
    fi
}

init_database() {
    echo -e "${GREEN}检测 MySQL 数据库是否已初始化...${RESET}"
    docker exec -i $MYSQL_CONTAINER mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "USE $MYSQL_DB;" 2>/dev/null || {
        echo -e "${GREEN}数据库未初始化，正在初始化...${RESET}"
        docker exec -i $MYSQL_CONTAINER mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF
        echo -e "${GREEN}数据库初始化完成${RESET}"
    }
}

start_api() {
    init_env
    init_database
    if ! docker ps -a --format '{{.Names}}' | grep -q "$API_CONTAINER"; then
        docker run -d --name $API_CONTAINER --restart always \
            -p $API_PORT:3000 \
            --env-file $DEFAULT_DATA/.env \
            -v $DEFAULT_DATA:/data \
            $API_IMAGE
        echo -e "${GREEN}New API 已启动${RESET}"
    else
        docker start $API_CONTAINER
        echo -e "${GREEN}New API 容器已启动${RESET}"
    fi
    show_ip_port
}

stop_api() { docker stop $API_CONTAINER && echo -e "${GREEN}New API 已停止${RESET}"; }

restart_api() { docker restart $API_CONTAINER && echo -e "${GREEN}New API 已重启${RESET}"; }

update_api() {
    docker pull $API_IMAGE
    docker stop $API_CONTAINER
    docker rm $API_CONTAINER
    start_api
    echo -e "${GREEN}更新完成${RESET}"
}

uninstall() {
    docker stop $API_CONTAINER $MYSQL_CONTAINER 2>/dev/null || true
    docker rm $API_CONTAINER $MYSQL_CONTAINER 2>/dev/null || true
    rm -rf $DEFAULT_DATA
    echo -e "${GREEN}卸载完成${RESET}"
}

view_logs() { docker logs -f $API_CONTAINER; }

view_mysql_logs() { docker logs -f $MYSQL_CONTAINER; }

# ================== 菜单 ==================
while true; do
    echo -e "${YELLOW}====== New API 管理菜单 ======${RESET}"
    echo "1. 启动服务"
    echo "2. 停止服务"
    echo "3. 重启服务"
    echo "4. 更新服务"
    echo "5. 卸载服务"
    echo "6. 查看 API 日志"
    echo "7. 查看数据库日志"
    echo "8. 显示访问 IP:端口"
    echo "0. 退出"
    read -rp "请输入编号: " choice

    case $choice in
        1)
            read -rp "请输入端口号(默认 $DEFAULT_PORT): " API_PORT
            API_PORT=${API_PORT:-$DEFAULT_PORT}
            start_mysql
            start_api
            pause
            ;;
        2) stop_api; pause ;;
        3) restart_api; pause ;;
        4) update_api; pause ;;
        5) uninstall; pause ;;
        6) view_logs ;;
        7) view_mysql_logs ;;
        8) show_ip_port; pause ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效输入${RESET}" ;;
    esac
done
