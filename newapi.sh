#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# ================== 默认配置 ==================
APP_DIR="/opt/newapi"
DOCKER_COMPOSE="$APP_DIR/docker-compose.yml"
ENV_FILE="$APP_DIR/.env"

MYSQL_CONTAINER="mysql"
MYSQL_ROOT_PASSWORD="123456"
MYSQL_DB="new-api"
MYSQL_USER="new-api"
MYSQL_PASSWORD="123456"
REDIS_CONTAINER="redis"
NEWAPI_CONTAINER="new-api"
DEFAULT_PORT=3000
APP_PORT=$DEFAULT_PORT

# ================== 工具函数 ==================
pause() {
    read -rp "按回车继续..."
}

get_ip() {
    ip addr show | awk '/inet / {if($2!="127.0.0.1/8"){split($2,a,"/"); print a[1]}}' | head -n1
}

generate_env() {
    mkdir -p "$APP_DIR"
    cat >"$ENV_FILE" <<EOF
SQL_DSN=$MYSQL_USER:$MYSQL_PASSWORD@tcp(mysql:3306)/$MYSQL_DB
REDIS_CONN_STRING=redis://redis
TZ=Asia/Shanghai
EOF
    echo -e "${GREEN}.env 文件已生成${RESET}"
}

generate_compose() {
    cat >"$DOCKER_COMPOSE" <<EOF
services:
  new-api:
    image: calciumion/new-api:latest
    container_name: $NEWAPI_CONTAINER
    restart: always
    command: --log-dir /app/logs
    ports:
      - "$APP_PORT:3000"
    volumes:
      - $APP_DIR/data:/data
      - $APP_DIR/logs:/app/logs
    environment:
      - SQL_DSN=$MYSQL_USER:$MYSQL_PASSWORD@tcp(mysql:3306)/$MYSQL_DB
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
    image: mysql:8
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
    docker exec -i $MYSQL_CONTAINER mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "USE \`$MYSQL_DB\`;" 2>/dev/null || {
        echo -e "${GREEN}数据库未初始化，正在初始化...${RESET}"

        echo -e "${GREEN}等待 MySQL 启动...${RESET}"
        until docker exec -i $MYSQL_CONTAINER mysqladmin ping -uroot -p$MYSQL_ROOT_PASSWORD --silent &>/dev/null; do
            sleep 2
        done

        docker exec -i $MYSQL_CONTAINER bash -c "MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -uroot <<EOF
CREATE DATABASE IF NOT EXISTS \`$MYSQL_DB\`;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON \`$MYSQL_DB\`.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF"
        echo -e "${GREEN}数据库初始化完成${RESET}"
    }
}

start_service() {
    generate_env
    generate_compose
    docker network ls | grep -q newapi_default || docker network create newapi_default
    docker-compose -f "$DOCKER_COMPOSE" up -d mysql redis
    init_database
    docker-compose -f "$DOCKER_COMPOSE" up -d new-api
    echo -e "${GREEN}访问地址: http://$(get_ip):$APP_PORT${RESET}"
}

stop_service() {
    docker-compose -f "$DOCKER_COMPOSE" down
    echo -e "${GREEN}服务已停止${RESET}"
}

restart_service() {
    stop_service
    start_service
}

update_service() {
    docker pull calciumion/new-api:latest
    restart_service
    echo -e "${GREEN}服务已更新${RESET}"
}

uninstall_service() {
    docker-compose -f "$DOCKER_COMPOSE" down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}服务已卸载${RESET}"
}

view_logs() {
    docker logs -f $NEWAPI_CONTAINER
}

view_mysql_logs() {
    docker logs -f $MYSQL_CONTAINER
}

change_port() {
    read -rp "请输入访问端口(默认 $DEFAULT_PORT): " APP_PORT
    APP_PORT=${APP_PORT:-$DEFAULT_PORT}
    echo -e "${GREEN}端口已设置为 $APP_PORT，正在重新生成配置并重启服务...${RESET}"
    restart_service
}

show_ip_port() {
    echo -e "${GREEN}访问地址: http://$(get_ip):$APP_PORT${RESET}"
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
    read -rp "请选择操作: " choice
    case $choice in
        1) start_service ;;
        2) stop_service ;;
        3) restart_service ;;
        4) update_service ;;
        5) uninstall_service ;;
        6) view_logs ;;
        7) view_mysql_logs ;;
        8) change_port ;;
        9) show_ip_port ;;
        0) exit ;;
        *) echo -e "${RED}无效选择${RESET}" ;;
    esac
done
