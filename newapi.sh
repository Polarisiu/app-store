#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 默认配置 ==================
INSTALL_DIR="/opt/newapi"
MYSQL_CONTAINER="mysql"
MYSQL_ROOT_PASSWORD="123456"
MYSQL_DB="new-api"
MYSQL_USER="new-api"
MYSQL_PASSWORD="123456"
DEFAULT_PORT=3000
API_CONTAINER="new-api"
REDIS_CONTAINER="redis"
PORT=$DEFAULT_PORT

mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# ================== 生成 .env 文件 ==================
generate_env() {
    cat >.env <<EOF
SQL_DSN=${MYSQL_USER}:${MYSQL_PASSWORD}@tcp(${MYSQL_CONTAINER}:3306)/${MYSQL_DB}
REDIS_CONN_STRING=redis://redis
TZ=Asia/Shanghai
EOF
    echo -e "${GREEN}.env 文件已生成${RESET}"
}

# ================== 生成 docker-compose.yml ==================
generate_compose() {
    cat >docker-compose.yml <<EOF
services:
  $API_CONTAINER:
    image: calciumion/new-api:latest
    container_name: $API_CONTAINER
    restart: always
    command: --log-dir /app/logs
    ports:
      - "${PORT}:3000"
    volumes:
      - ./data:/data
      - ./logs:/app/logs
    environment:
      - SQL_DSN=root:${MYSQL_ROOT_PASSWORD}@tcp(${MYSQL_CONTAINER}:3306)/${MYSQL_DB}
      - REDIS_CONN_STRING=redis://redis
      - TZ=Asia/Shanghai
    depends_on:
      - $REDIS_CONTAINER
      - $MYSQL_CONTAINER

  $REDIS_CONTAINER:
    image: redis:latest
    container_name: $REDIS_CONTAINER
    restart: always

  $MYSQL_CONTAINER:
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

# ================== 等待 MySQL 启动 ==================
wait_mysql() {
    echo -e "${GREEN}等待 MySQL 启动...${RESET}"
    until MYSQL_PWD=$MYSQL_ROOT_PASSWORD docker exec $MYSQL_CONTAINER mysqladmin ping -uroot --silent; do
        sleep 2
    done
}

# ================== 初始化数据库 ==================
init_database() {
    echo -e "${GREEN}检测 MySQL 数据库是否已初始化...${RESET}"
    MYSQL_PWD=$MYSQL_ROOT_PASSWORD docker exec -i $MYSQL_CONTAINER mysql -uroot -e "USE $MYSQL_DB;" 2>/dev/null || {
        echo -e "${GREEN}数据库未初始化，正在初始化...${RESET}"
        docker exec -i $MYSQL_CONTAINER bash -c "MYSQL_PWD=$MYSQL_ROOT_PASSWORD mysql -uroot <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF"
        echo -e "${GREEN}数据库初始化完成${RESET}"
    }
}

# ================== 启动服务 ==================
start_service() {
    generate_env
    generate_compose
    docker-compose up -d $MYSQL_CONTAINER
    wait_mysql
    init_database
    docker-compose up -d $API_CONTAINER $REDIS_CONTAINER
    echo -e "${GREEN}访问地址: http://$(curl -s ifconfig.me):$PORT${RESET}"
}

# ================== 停止服务 ==================
stop_service() {
    docker-compose down
    echo -e "${GREEN}服务已停止${RESET}"
}

# ================== 重启服务 ==================
restart_service() {
    stop_service
    start_service
}

# ================== 更新服务 ==================
update_service() {
    docker pull calciumion/new-api:latest
    restart_service
    echo -e "${GREEN}New API 已更新${RESET}"
}

# ================== 卸载服务 ==================
uninstall_service() {
    docker-compose down -v
    rm -rf $INSTALL_DIR
    echo -e "${GREEN}New API 已卸载${RESET}"
}

# ================== 查看日志 ==================
show_api_log() {
    docker logs -f $API_CONTAINER
}

show_mysql_log() {
    docker logs -f $MYSQL_CONTAINER
}

# ================== 修改访问端口 ==================
change_port() {
    read -p "请输入访问端口(默认 $DEFAULT_PORT): " new_port
    PORT=${new_port:-$DEFAULT_PORT}
    echo -e "${GREEN}端口已设置为 $PORT，正在重新生成配置并重启服务...${RESET}"
    restart_service
}

# ================== 显示访问 IP:端口 ==================
show_ip() {
    echo -e "${GREEN}访问地址: http://$(curl -s ifconfig.me):$PORT${RESET}"
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
    echo -e "${GREEN}9. 显示访问 IP:端口${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    read -p "请选择操作: " choice
    case $choice in
        1) start_service ;;
        2) stop_service ;;
        3) restart_service ;;
        4) update_service ;;
        5) uninstall_service ;;
        6) show_api_log ;;
        7) show_mysql_log ;;
        8) change_port ;;
        9) show_ip ;;
        0) exit ;;
        *) echo -e "${GREEN}无效选项${RESET}" ;;
    esac
done
