#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 默认配置 ==================
NEWAPI_DIR="/opt/newapi"
MYSQL_CONTAINER="mysql"
MYSQL_ROOT_PASSWORD="123456"
MYSQL_DB="new-api"
MYSQL_USER="newapi"
MYSQL_PASSWORD="123456"
REDIS_CONTAINER="redis"
NEWAPI_CONTAINER="new-api"
DEFAULT_PORT=3000

# ================== 工具函数 ==================
generate_env() {
    mkdir -p "$NEWAPI_DIR"
    cat > "$NEWAPI_DIR/.env" <<EOF
SQL_DSN=$MYSQL_USER:$MYSQL_PASSWORD@tcp(mysql:3306)/$MYSQL_DB
REDIS_CONN_STRING=redis://redis
TZ=Asia/Shanghai
EOF
    echo -e "${GREEN}.env 文件已生成${RESET}"
}

generate_compose() {
    cat > "$NEWAPI_DIR/docker-compose.yml" <<EOF
services:
  new-api:
    image: calciumion/new-api:latest
    container_name: $NEWAPI_CONTAINER
    restart: always
    command: --log-dir /app/logs
    ports:
      - "$PORT:3000"
    volumes:
      - $NEWAPI_DIR/data:/data
      - $NEWAPI_DIR/logs:/app/logs
    environment:
      - SQL_DSN=root:$MYSQL_ROOT_PASSWORD@tcp(mysql:3306)/$MYSQL_DB
      - REDIS_CONN_STRING=redis://redis
      - TZ=Asia/Shanghai
    depends_on:
      - redis
      - mysql

  redis:
    image: redis:latest
    container_name: $REDIS_CONTAINER
    restart: always

  mysql:
    image: mysql:8.2
    container_name: $MYSQL_CONTAINER
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
      MYSQL_DATABASE: $MYSQL_DB
    volumes:
      - mysql_data:/var/lib/mysql

volumes:
  mysql_data:
EOF
    echo -e "${GREEN}docker-compose.yml 文件已生成${RESET}"
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

get_ip_port() {
    IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}访问地址: http://$IP:$PORT${RESET}"
}

start_service() {
    generate_env
    generate_compose
    docker-compose -f "$NEWAPI_DIR/docker-compose.yml" up -d
    echo -e "${GREEN}等待 MySQL 启动...${RESET}"
    until docker exec $MYSQL_CONTAINER mysqladmin ping -uroot -p$MYSQL_ROOT_PASSWORD --silent; do
        sleep 2
    done
    init_database
    docker-compose -f "$NEWAPI_DIR/docker-compose.yml" up -d $NEWAPI_CONTAINER
    get_ip_port
}

stop_service() {
    docker-compose -f "$NEWAPI_DIR/docker-compose.yml" down
}

restart_service() {
    docker-compose -f "$NEWAPI_DIR/docker-compose.yml" restart
}

view_logs_newapi() {
    docker logs -f $NEWAPI_CONTAINER
}

view_logs_mysql() {
    docker logs -f $MYSQL_CONTAINER
}

update_service() {
    docker pull calciumion/new-api:latest
    docker-compose -f "$NEWAPI_DIR/docker-compose.yml" up -d $NEWAPI_CONTAINER
}

uninstall_service() {
    docker-compose -f "$NEWAPI_DIR/docker-compose.yml" down -v
    rm -rf "$NEWAPI_DIR"
    echo -e "${GREEN}New API 已卸载${RESET}"
}

modify_port() {
    read -p "请输入访问端口(默认 $DEFAULT_PORT): " PORT
    PORT=${PORT:-$DEFAULT_PORT}
    echo -e "${GREEN}端口已设置为 $PORT，正在更新配置并重启 New API...${RESET}"
    generate_env
    generate_compose
    docker-compose -f "$NEWAPI_DIR/docker-compose.yml" up -d $NEWAPI_CONTAINER
    get_ip_port
}

# ================== 菜单 ==================
while true; do
    echo -e "${GREEN}====== New API 管理菜单 ======${RESET}"
    echo -e "${GREEN}1. 启动服务${RESET}"
    echo -e "${GREEN}2. 停止服务${RESET}"
    echo -e "${GREEN}3. 重启服务${RESET}"
    echo -e "${GREEN}4. 更新 New API${RESET}"
    echo -e "${GREEN}5. 卸载服务${RESET}"
    echo -e "${GREEN}6. 查看 New API 日志${RESET}"
    echo -e "${GREEN}7. 查看 MySQL 日志${RESET}"
    echo -e "${GREEN}8. 修改访问端口${RESET}"
    echo -e "${GREEN}9. 显示访问地址${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    read -p "请选择操作: " choice
    case "$choice" in
        1) start_service ;;
        2) stop_service ;;
        3) restart_service ;;
        4) update_service ;;
        5) uninstall_service ;;
        6) view_logs_newapi ;;
        7) view_logs_mysql ;;
        8) modify_port ;;
        9) get_ip_port ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选择${RESET}" ;;
    esac
done
