#!/bin/bash
# Cloudreve 管理脚本（部署 + 管理菜单，统一目录 /opt/cloudreve）

BASE_DIR="/opt/cloudreve"
COMPOSE_FILE="$BASE_DIR/docker-compose.yml"
ENV_FILE="$BASE_DIR/.env"

# 默认值
DEFAULT_PORT=5212
DEFAULT_DB_PASS="55689"
DEFAULT_REDIS_PASS="55697"

# 颜色
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

# 确保目录存在
mkdir -p "$BASE_DIR"

# 部署函数
deploy() {
    echo -e "${GREEN}=== Cloudreve 部署 ===${RESET}"
    read -p "$(echo -e ${GREEN}请输入 Cloudreve 端口 [默认: $DEFAULT_PORT]: ${RESET})" PORT
    PORT=${PORT:-$DEFAULT_PORT}

    read -p "$(echo -e ${GREEN}请输入 PostgreSQL 密码 [默认: $DEFAULT_DB_PASS]: ${RESET})" DB_PASSWORD
    DB_PASSWORD=${DB_PASSWORD:-$DEFAULT_DB_PASS}

    read -p "$(echo -e ${GREEN}请输入 Redis 密码 [默认: $DEFAULT_REDIS_PASS]: ${RESET})" REDIS_PASSWORD
    REDIS_PASSWORD=${REDIS_PASSWORD:-$DEFAULT_REDIS_PASS}

    # 生成 .env 文件
    cat > $ENV_FILE <<EOF
PORT=$PORT
DB_PASSWORD=$DB_PASSWORD
REDIS_PASSWORD=$REDIS_PASSWORD
EOF
    echo -e "${GREEN}[√] 已生成 $ENV_FILE${RESET}"

    # 生成 docker-compose.yml
    cat > $COMPOSE_FILE <<EOF
services:
  cloudreve:
    image: cloudreve/cloudreve:latest
    container_name: cloudreve-backend
    depends_on:
      - postgresql
      - redis
    restart: always
    ports:
      - "127.0.0.1:$PORT:5212"
      - "6888:6888"
      - "6888:6888/udp"
    environment:
      - CR_CONF_Database.Type=postgres
      - CR_CONF_Database.Host=postgresql
      - CR_CONF_Database.User=cloudreve
      - CR_CONF_Database.Password=\${DB_PASSWORD}
      - CR_CONF_Database.Name=cloudreve
      - CR_CONF_Database.Port=5432
      - CR_CONF_Redis.Server=redis:6379
      - CR_CONF_Redis.Password=\${REDIS_PASSWORD}
    volumes:
      - ${BASE_DIR}/cloudreve:/cloudreve/data

  postgresql:
    image: postgres:17
    container_name: postgresql
    environment:
      - POSTGRES_USER=cloudreve
      - POSTGRES_PASSWORD=\${DB_PASSWORD}
      - POSTGRES_DB=cloudreve
    volumes:
      - ${BASE_DIR}/postgres:/var/lib/postgresql/data

  redis:
    image: redis:latest
    container_name: redis
    command: ["redis-server", "--requirepass", "\${REDIS_PASSWORD}"]
    volumes:
      - ${BASE_DIR}/redis:/data
EOF
    echo -e "${GREEN}[√] 已生成 $COMPOSE_FILE${RESET}"

    cd "$BASE_DIR" && docker compose up -d
    echo -e "${GREEN}=== 部署完成！===${RESET}"
    echo -e "${GREEN}Cloudreve 管理面板: http://127.0.0.1:$PORT${RESET}"
    echo -e "${GREEN}📂 数据目录: /opt/cloudreve${RESET}"
}

# 卸载函数
uninstall() {
    echo -e "${RED}警告: 这将删除 Cloudreve, PostgreSQL, Redis 及其数据！${RESET}"
    read -p "是否继续? (y/N): " CONFIRM
    if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
        cd "$BASE_DIR" && docker compose down -v
        rm -rf "$BASE_DIR"
        echo -e "${GREEN}[√] 已卸载 Cloudreve${RESET}"
    else
        echo -e "${GREEN}已取消操作${RESET}"
    fi
}

# 更新函数
update() {
    echo -e "${GREEN}=== 更新 Cloudreve / PostgreSQL / Redis 镜像 ===${RESET}"
    cd "$BASE_DIR" && docker compose pull && docker compose up -d
    echo -e "${GREEN}[√] 更新完成${RESET}"
}

# 管理菜单
while true; do
    clear
    echo -e "${GREEN}=== Cloudreve 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装部署${RESET}"
    echo -e "${GREEN}2) 启动${RESET}"
    echo -e "${GREEN}3) 停止${RESET}"
    echo -e "${GREEN}4) 重启${RESET}"
    echo -e "${GREEN}5) 查看日志${RESET}"
    echo -e "${GREEN}6) 卸载${RESET}"
    echo -e "${GREEN}7) 更新${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "$(echo -e ${GREEN}请输入选项: ${RESET})" CHOICE

    case $CHOICE in
        1) deploy ;;
        2) cd "$BASE_DIR" && docker compose start ;;
        3) cd "$BASE_DIR" && docker compose stop ;;
        4) cd "$BASE_DIR" && docker compose restart ;;
        5) cd "$BASE_DIR" && docker compose logs -f ;;
        6) uninstall ;;
        7) update ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项，请重试${RESET}" ;;
    esac
done
