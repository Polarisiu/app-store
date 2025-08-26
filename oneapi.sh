#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 默认配置 ==================
COMPOSE_FILE="docker-compose.yml"
DEFAULT_PORT=3000
DEFAULT_DB_ROOT_PASS="test2024"

# 获取服务器IP
get_ip() {
    IP=$(curl -s ifconfig.me || curl -s ip.sb || hostname -I | awk '{print $1}')
    echo "$IP"
}

# ================== 安装 MySQL 容器 ==================
install_mysql() {
    # 检测是否已有 mysql 容器
    if docker ps -a --format '{{.Names}}' | grep -q '^mysql$'; then
        echo -e "${GREEN}⚠️ 已存在名为 mysql 的容器，正在删除旧容器...${RESET}"
        docker rm -f mysql
    fi

    echo -e "${GREEN}请输入 MySQL root 密码 (默认: ${DEFAULT_DB_ROOT_PASS}): ${RESET}"
    read DB_ROOT_PASS
    DB_ROOT_PASS=${DB_ROOT_PASS:-$DEFAULT_DB_ROOT_PASS}

    echo -e "${GREEN}📦 正在安装 MySQL 容器...${RESET}"
    docker run -d \
        --name mysql \
        --restart always \
        -e MYSQL_ROOT_PASSWORD=${DB_ROOT_PASS} \
        -p 3306:3306 \
        -v ./volumes/mysql/data:/var/lib/mysql \
        mysql:8.0

    echo -e "${GREEN}✅ MySQL 已启动，地址: mysql:3306  Root密码: ${DB_ROOT_PASS}${RESET}"
}


# ================== 部署 One-API ==================
deploy() {
    echo -e "${GREEN}请输入 One-API 端口 (默认: ${DEFAULT_PORT}): ${RESET}"
    read PORT
    PORT=${PORT:-$DEFAULT_PORT}

    echo -e "${GREEN}请输入 MySQL root 密码 (默认: ${DEFAULT_DB_ROOT_PASS}): ${RESET}"
    read DB_ROOT_PASS
    DB_ROOT_PASS=${DB_ROOT_PASS:-$DEFAULT_DB_ROOT_PASS}

    # 检查 MySQL 容器是否在运行
    if ! docker ps --format '{{.Names}}' | grep -q '^mysql$'; then
        echo -e "${GREEN}⚠️ 未检测到 MySQL 容器，是否安装？(y/n): ${RESET}"
        read choice
        if [[ "$choice" == "y" ]]; then
            install_mysql
            sleep 15
        else
            echo -e "${GREEN}❌ 未安装 MySQL，部署中止${RESET}"
            return
        fi
    fi

    DB_NAME="oneapi"
    DB_USER="oneapi_user"
    DB_PASS="oneapi_pass"

    echo -e "${GREEN}🔧 正在初始化数据库...${RESET}"
    docker exec -i mysql mysql -uroot -p${DB_ROOT_PASS} <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    echo -e "${GREEN}✅ 数据库初始化完成${RESET}"

    SQL_DSN="${DB_USER}:${DB_PASS}@tcp(mysql:3306)/${DB_NAME}?charset=utf8mb4&parseTime=True&loc=Local"
    SESSION_SECRET=$(openssl rand -hex 32)

    mkdir -p ./volumes/one-api/data ./volumes/one-api/logs ./volumes/data-gym-cache
    chmod -R 777 ./volumes

    cat > ${COMPOSE_FILE} <<EOF
services:
  one-api:
    container_name: one-api
    image: justsong/one-api:latest
    restart: always
    command: --log-dir /app/logs
    ports:
      - "${PORT}:3000"
    volumes:
      - ./volumes/one-api/data:/data
      - ./volumes/one-api/logs:/app/logs
      - ./volumes/data-gym-cache:/tmp/data-gym-cache
    environment:
      - SQL_DSN=${SQL_DSN}
      - SESSION_SECRET=${SESSION_SECRET}
      - TZ=Asia/Shanghai
    depends_on:
      - mysql
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O - http://localhost:3000/api/status | grep '\"success\":true' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  mysql:
    image: mysql:8.0
    container_name: mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASS}
    ports:
      - "3306:3306"
    volumes:
      - ./volumes/mysql/data:/var/lib/mysql
EOF

    docker compose up -d
    echo -e "${GREEN}🎉 部署完成! 访问地址: http://$(get_ip):${PORT}${RESET}"
    echo -e "${GREEN}🎉 部署完成! 初始账号用户名为 root，密码为 123456${RESET}"
}

# ================== 菜单 ==================
while true; do
    echo -e "\n${GREEN}========= One-API 管理菜单 =========${RESET}"
    echo -e "${GREEN}1. 部署 One-API${RESET}"
    echo -e "${GREEN}2. 启动 One-API${RESET}"
    echo -e "${GREEN}3. 停止 One-API${RESET}"
    echo -e "${GREEN}4. 重启 One-API${RESET}"
    echo -e "${GREEN}5. 更新并重启 One-API${RESET}"
    echo -e "${GREEN}6. 查看日志${RESET}"
    echo -e "${GREEN}7. 查看状态${RESET}"
    echo -e "${GREEN}8. 删除 One-API${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -ne "${GREEN}请选择操作: ${RESET}"
    read choice

    case $choice in
        1) deploy ;;
        2) docker compose up -d ;;
        3) docker compose down ;;
        4) docker compose down && docker compose up -d ;;
        5) docker compose pull one-api || docker pull justsong/one-api:latest && docker compose down && docker compose up -d ;;
        6) echo -e "${GREEN}📜 正在查看日志，按回车返回菜单${RESET}"; ( docker logs -f one-api & pid=$! ; read; kill $pid ) ;;
        7) docker ps --filter "name=one-api"; echo -e "${GREEN}🌍 访问地址: http://$(get_ip):$(grep -E '^[[:space:]]*-[[:space:]]*[0-9]+:3000' ${COMPOSE_FILE} | sed -E 's/.*- ([0-9]+):3000/\1/')${RESET}" ;;
        8) docker compose down -v && rm -f ${COMPOSE_FILE} && echo -e "${GREEN}❌ One-API 已删除${RESET}" ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选项，请重新输入${RESET}" ;;
    esac
done
