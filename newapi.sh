#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ================== 默认配置 ==================
DEFAULT_PORT=3000
CONTAINER_NAME="new-api"
MYSQL_CONTAINER="newapi-mysql"
MYSQL_ROOT_PASSWORD="root123"
MYSQL_DB="newapi"
MYSQL_USER="newapi"
MYSQL_PASSWORD="newapi123"
DATA_DIR="/opt/newapi"
COMPOSE_FILE="$DATA_DIR/docker-compose.yml"
ENV_FILE="$DATA_DIR/.env"

# ================== 工具函数 ==================
pause() { read -rp "按任意键继续..." }

show_ip_port() {
  IP=$(hostname -I | awk '{print $1}')
  echo -e "${GREEN}访问地址: http://${IP}:${APP_PORT}${RESET}"
}

create_env_file() {
  mkdir -p "$DATA_DIR"
  cat > "$ENV_FILE" <<EOF
APP_PORT=$APP_PORT
MYSQL_HOST=$MYSQL_CONTAINER
MYSQL_PORT=3306
MYSQL_DB=$MYSQL_DB
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
EOF
  echo -e "${GREEN}.env 文件已生成${RESET}"
}

create_compose_file() {
  mkdir -p "$DATA_DIR"
  cat > "$COMPOSE_FILE" <<EOF
version: '3'
services:
  $MYSQL_CONTAINER:
    image: mysql:8.0
    container_name: $MYSQL_CONTAINER
    environment:
      - MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
    volumes:
      - $DATA_DIR/mysql:/var/lib/mysql
    restart: always

  $CONTAINER_NAME:
    image: calciumion/new-api:latest
    container_name: $CONTAINER_NAME
    environment:
      - TZ=Asia/Shanghai
    ports:
      - "$APP_PORT:3000"
    volumes:
      - $DATA_DIR:/data
    depends_on:
      - $MYSQL_CONTAINER
    restart: always
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

install_api() {
  read -rp "设置 API 端口（默认 $DEFAULT_PORT）: " APP_PORT
  APP_PORT=${APP_PORT:-$DEFAULT_PORT}

  create_env_file
  create_compose_file

  echo -e "${GREEN}启动 MySQL 容器...${RESET}"
  docker-compose -f "$COMPOSE_FILE" up -d $MYSQL_CONTAINER
  sleep 5
  init_database

  echo -e "${GREEN}启动 New API 容器...${RESET}"
  docker-compose -f "$COMPOSE_FILE" up -d $CONTAINER_NAME

  show_ip_port
}

uninstall_api() {
  docker-compose -f "$COMPOSE_FILE" down
  echo -e "${YELLOW}是否删除数据目录 $DATA_DIR ? [y/N] \c${RESET}"
  read ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -rf "$DATA_DIR"
    echo -e "${GREEN}数据目录已删除${RESET}"
  fi
  echo -e "${GREEN}卸载完成${RESET}"
}

update_api() {
  docker pull calciumion/new-api:latest
  docker-compose -f "$COMPOSE_FILE" up -d $CONTAINER_NAME
  show_ip_port
}

start_api() {
  docker-compose -f "$COMPOSE_FILE" up -d $CONTAINER_NAME
  show_ip_port
}

stop_api() {
  docker-compose -f "$COMPOSE_FILE" stop $CONTAINER_NAME
  echo -e "${GREEN}服务已停止${RESET}"
}

restart_api() {
  docker-compose -f "$COMPOSE_FILE" restart $CONTAINER_NAME
  show_ip_port
}

logs_api() {
  docker logs -f $CONTAINER_NAME
}

logs_mysql() {
  docker logs -f $MYSQL_CONTAINER
}

# ================== 菜单 ==================
while true; do
  echo -e "${GREEN}===== New API 管理脚本 =====${RESET}"
  echo -e "${YELLOW}1. 安装 API${RESET}"
  echo -e "${YELLOW}2. 卸载 API${RESET}"
  echo -e "${YELLOW}3. 更新 API${RESET}"
  echo -e "${YELLOW}4. 启动服务${RESET}"
  echo -e "${YELLOW}5. 停止服务${RESET}"
  echo -e "${YELLOW}6. 重启服务${RESET}"
  echo -e "${YELLOW}7. 查看 API 日志${RESET}"
  echo -e "${YELLOW}8. 查看数据库日志${RESET}"
  echo -e "${YELLOW}9. 显示访问地址${RESET}"
  echo -e "${YELLOW}0. 退出${RESET}"

  read -rp "请输入编号: " choice
  case $choice in
    1) install_api ;;
    2) uninstall_api ;;
    3) update_api ;;
    4) start_api ;;
    5) stop_api ;;
    6) restart_api ;;
    7) logs_api ;;
    8) logs_mysql ;;
    9) show_ip_port ;;
    0) exit 0 ;;
    *) echo -e "${RED}无效选项${RESET}" ;;
  esac
done
