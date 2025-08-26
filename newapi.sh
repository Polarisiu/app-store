#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 配置 ==================
DATA_PATH="./data"
LOGS_PATH="./logs"
ENV_FILE="$DATA_PATH/.env"
DEFAULT_API_PORT=3000
COMPOSE_FILE="./docker-compose.yml"

MYSQL_CONTAINER="mysql"
MYSQL_ROOT_PASSWORD="123456"
MYSQL_DB="new-api"
MYSQL_USER="newapiuser"
MYSQL_PASSWORD="newapipwd"

API_CONTAINER="new-api"

# ================== 工具函数 ==================
pause() { read -rp "按回车键继续..." dummy; }

check_create_dirs() {
    [ ! -d "$DATA_PATH" ] && mkdir -p "$DATA_PATH"
    [ ! -d "$LOGS_PATH" ] && mkdir -p "$LOGS_PATH"
}

generate_env() {
    if [ ! -f "$ENV_FILE" ]; then
        cat > "$ENV_FILE" <<EOF
SQL_DSN=$MYSQL_USER:$MYSQL_PASSWORD@tcp(mysql:3306)/$MYSQL_DB
REDIS_CONN_STRING=redis://redis
TZ=Asia/Shanghai
EOF
        echo -e "${GREEN}.env 文件已生成${RESET}"
    fi
}

wait_for_mysql() {
    echo -e "${GREEN}等待 MySQL 启动...${RESET}"
    until docker exec -i $MYSQL_CONTAINER mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "SELECT 1;" >/dev/null 2>&1; do
        sleep 2
    done
    echo -e "${GREEN}MySQL 已启动${RESET}"
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

start_services() {
    check_create_dirs
    generate_env
    docker-compose -f $COMPOSE_FILE up -d mysql redis
    wait_for_mysql
    init_database
    docker-compose -f $COMPOSE_FILE up -d $API_CONTAINER
    echo -e "${GREEN}服务启动完成${RESET}"
    echo -e "${GREEN}访问地址: $(hostname -I | awk '{print $1}'):$API_PORT${RESET}"
}

stop_services() {
    docker-compose -f $COMPOSE_FILE down
    echo -e "${GREEN}服务已停止${RESET}"
}

restart_services() {
    stop_services
    start_services
    echo -e "${GREEN}服务已重启${RESET}"
}

update_api() {
    docker-compose -f $COMPOSE_FILE pull $API_CONTAINER
    restart_services
    echo -e "${GREEN}New API 已更新${RESET}"
}

uninstall_services() {
    docker-compose -f $COMPOSE_FILE down -v
    echo -e "${GREEN}服务及数据库数据已卸载${RESET}"
}

logs_api() {
    docker-compose -f $COMPOSE_FILE logs -f $API_CONTAINER
}

logs_mysql() {
    docker-compose -f $COMPOSE_FILE logs -f $MYSQL_CONTAINER
}

change_port() {
    read -rp "请输入新的访问端口: " new_port
    API_PORT=$new_port
    echo -e "${GREEN}端口已更新为 $API_PORT，请修改 docker-compose.yml 对应映射后重启服务${RESET}"
}

show_ip() {
    echo -e "${GREEN}访问地址: $(hostname -I | awk '{print $1}'):$API_PORT${RESET}"
}

# ================== 菜单 ==================
while true; do
    clear
    echo -e "${GREEN}====== New API 管理菜单 ======${RESET}"
    echo -e "${GREEN}1. 启动服务${RESET}"
    echo -e "${GREEN}2. 停止服务${RESET}"
    echo -e "${GREEN}3. 重启服务${RESET}"
    echo -e "${GREEN}4. 更新 New API${RESET}"
    echo -e "${GREEN}5. 卸载服务${RESET}"
    echo -e "${GREEN}6. 查看 New API 日志${RESET}"
    echo -e "${GREEN}7. 查看 MySQL 日志${RESET}"
    echo -e "${GREEN}8. 修改访问端口${RESET}"
    echo -e "${GREEN}9. 显示访问 IP:端口${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    read -rp "请选择操作: " choice
    case $choice in
        1) start_services; pause ;;
        2) stop_services; pause ;;
        3) restart_services; pause ;;
        4) update_api; pause ;;
        5) uninstall_services; pause ;;
        6) logs_api ;;
        7) logs_mysql ;;
        8) change_port ;;
        9) show_ip; pause ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选项${RESET}"; pause ;;
    esac
done
