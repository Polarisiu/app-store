#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 默认配置 ==================
COMPOSE_FILE="docker-compose.yml"
DEFAULT_PORT=3000
DEFAULT_SQL_DSN="root:test2024@tcp(111.18.9.111:3306)/oneapi?charset=utf8mb4&parseTime=True&loc=Local"
DEFAULT_SECRET="random_string"

# 获取服务器IP（公网优先，本地备选）
get_ip() {
    IP=$(curl -s ifconfig.me || curl -s ip.sb || hostname -I | awk '{print $1}')
    echo "$IP"
}

# 获取配置文件中的端口
get_port() {
    if [[ -f ${COMPOSE_FILE} ]]; then
        PORT=$(grep -E "^[[:space:]]*-[[:space:]]*\"?[0-9]+:3000" ${COMPOSE_FILE} | head -n1 | sed -E 's/.*- "?([0-9]+):3000"?/\1/')
        echo "${PORT:-$DEFAULT_PORT}"
    else
        echo $DEFAULT_PORT
    fi
}

# ================== 函数 ==================
deploy() {
    echo -e "${GREEN}请输入 One-API 端口 (默认: ${DEFAULT_PORT}): ${RESET}"
    read PORT
    PORT=${PORT:-$DEFAULT_PORT}

    echo -e "${GREEN}请输入数据库连接 DSN (默认: ${DEFAULT_SQL_DSN}): ${RESET}"
    read SQL_DSN
    SQL_DSN=${SQL_DSN:-$DEFAULT_SQL_DSN}

    echo -e "${GREEN}请输入 Session Secret (默认: ${DEFAULT_SECRET}): ${RESET}"
    read SESSION_SECRET
    SESSION_SECRET=${SESSION_SECRET:-$DEFAULT_SECRET}

    mkdir -p ./volumes/one-api/data ./volumes/one-api/logs ./volumes/data-gym-cache
    chmod -R 777 ./volumes

    cat > ${COMPOSE_FILE} <<EOF
version: "3.8"

services:
  one-api:
    container_name: one-api
    image: one-api:latest
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
    healthcheck:
      test: ["CMD-SHELL", "wget -q -O - http://localhost:3000/api/status | grep '\"success\":true' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3
EOF

    docker compose up -d
    echo -e "${GREEN}🎉 部署完成! 访问地址: http://$(get_ip):${PORT}${RESET}"
    echo -e "${GREEN}🎉 部署完成! 初始账号用户名为 root，密码为 123456${RESET}"
}

start() {
    docker compose up -d
    echo -e "${GREEN}🚀 One-API 已启动: http://$(get_ip):$(get_port)${RESET}"
}

stop() {
    docker compose down
    echo -e "${GREEN}🛑 One-API 已停止${RESET}"
}

restart() {
    docker compose down
    docker compose up -d
    echo -e "${GREEN}🔄 One-API 已重启: http://$(get_ip):$(get_port)${RESET}"
}

update_restart() {
    echo -e "${GREEN}📥 正在拉取最新镜像...${RESET}"
    docker compose pull one-api || docker pull one-api:latest
    docker compose down
    docker compose up -d
    echo -e "${GREEN}🎉 One-API 已更新并重启: http://$(get_ip):$(get_port)${RESET}"
}

logs() {
    echo -e "${GREEN}📜 正在查看日志，按回车返回菜单${RESET}"
    ( docker logs -f one-api & pid=$! ; read; kill $pid )
}

status() {
    docker ps --filter "name=one-api"
    echo -e "${GREEN}🌍 访问地址: http://$(get_ip):$(get_port)${RESET}"
}

remove() {
    docker compose down -v
    rm -f ${COMPOSE_FILE}
    echo -e "${GREEN}❌ One-API 已删除${RESET}"
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
        2) start ;;
        3) stop ;;
        4) restart ;;
        5) update_restart ;;
        6) logs ;;
        7) status ;;
        8) remove ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选项，请重新输入${RESET}" ;;
    esac
done
