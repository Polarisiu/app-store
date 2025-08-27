#!/bin/bash
# ========================================
# Trilium 中文版 一键部署 & 菜单管理脚本
# ========================================

# 颜色定义
GREEN="\033[0;32m"
RESET="\033[0m"

COMPOSE_FILE="docker-compose.yml"
PORT_FILE=".trilium_port"

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then
    echo -e "${GREEN}请使用 root 权限运行脚本！${RESET}"
    exit 1
fi

# 检查 docker 是否安装
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${GREEN}未检测到 Docker，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | sh
    fi
    if ! command -v docker-compose &>/dev/null; then
        echo -e "${GREEN}未检测到 Docker Compose，正在安装...${RESET}"
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
}

# 生成 docker-compose.yml
create_compose() {
    read -p "请输入映射端口 (默认8080): " PORT
    PORT=${PORT:-8080}
    echo "$PORT" > $PORT_FILE
    cat > $COMPOSE_FILE <<EOF
services:
  trilium-cn:
    image: nriver/trilium-cn
    restart: always
    ports:
      - "$PORT:8080"
    volumes:
      - ./trilium-data:/root/trilium-data
    environment:
      - TRILIUM_DATA_DIR=/root/trilium-data
EOF
    echo -e "${GREEN}docker-compose.yml 已生成，映射端口: $PORT${RESET}"
}

# 启动服务
start_service() {
    docker-compose up -d
    local port=$(cat $PORT_FILE 2>/dev/null || echo 8080)
    echo -e "${GREEN}Trilium 已启动！访问: http://<服务器IP>:$port${RESET}"
}

# 停止服务
stop_service() {
    docker-compose down
    echo -e "${GREEN}Trilium 已停止！${RESET}"
}

# 重启服务
restart_service() {
    docker-compose down && docker-compose up -d
    echo -e "${GREEN}Trilium 已重启！${RESET}"
}

# 查看日志
view_logs() {
    docker-compose logs --tail=50
    echo -e "${GREEN}（仅显示最近50行日志）${RESET}"
}

# 查看状态
status_service() {
    docker-compose ps
}

# 更新服务
update_service() {
    docker-compose pull
    docker-compose up -d
    echo -e "${GREEN}Trilium 已更新并重启！${RESET}"
}

# 删除容器和数据
remove_all() {
    docker-compose down -v
    rm -rf trilium-data $COMPOSE_FILE $PORT_FILE
    echo -e "${GREEN}Trilium 及数据已删除！${RESET}"
}

# 主菜单
menu() {
    clear
    echo -e "${GREEN}========================================${RESET}"
    echo -e "${GREEN}     Trilium 中文版 一键部署管理菜单    ${RESET}"
    echo -e "${GREEN}========================================${RESET}"
    echo -e "${GREEN}1) 安装环境并生成配置${RESET}"
    echo -e "${GREEN}2) 启动 Trilium${RESET}"
    echo -e "${GREEN}3) 停止 Trilium${RESET}"
    echo -e "${GREEN}4) 重启 Trilium${RESET}"
    echo -e "${GREEN}5) 查看日志${RESET}"
    echo -e "${GREEN}6) 查看状态${RESET}"
    echo -e "${GREEN}7) 更新 Trilium${RESET}"
    echo -e "${GREEN}8) 删除 Trilium 及数据${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    echo -e "${GREEN}========================================${RESET}"
}

# 主循环
while true; do
    menu
    read -p "请输入选项: " choice
    case $choice in
        1) check_docker; create_compose ;;
        2) start_service ;;
        3) stop_service ;;
        4) restart_service ;;
        5) view_logs ;;
        6) status_service ;;
        7) update_service ;;
        8) remove_all ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选项，请重新输入！${RESET}" ;;
    esac
    read -p "按回车返回菜单..."
done
