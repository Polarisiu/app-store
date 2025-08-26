#!/bin/bash
set -e

# ================== 颜色定义 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 固定目录 ==================
WORKDIR="$HOME/newapi"
CONFIG_FILE="$WORKDIR/.config"
CONTAINER_NAME="new-api"
IMAGE_NAME="calciumion/new-api:latest"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$WORKDIR"

# ================== 工具函数 ==================
check_env() {
    if ! command -v docker &>/dev/null; then
        echo -e "${GREEN}错误: 未安装 Docker${RESET}"
        exit 1
    fi
}

get_ip() {
    hostname -I | awk '{print $1}'
}

save_config() {
    echo "PORT=$PORT" > "$CONFIG_FILE"
    echo "DATA_DIR=$DATA_DIR" >> "$CONFIG_FILE"
}

load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        PORT=3000
        DATA_DIR="$WORKDIR/data"
    fi
}

# ================== 功能函数 ==================
deploy_service() {
    echo -e "${GREEN}请输入映射端口 (默认 3000): ${RESET}"
    read PORT
    PORT=${PORT:-3000}

    echo -e "${GREEN}请输入数据存储目录 (默认 $WORKDIR/data): ${RESET}"
    read DATA_DIR
    DATA_DIR=${DATA_DIR:-$WORKDIR/data}

    mkdir -p "$DATA_DIR"

    docker run -d \
        --name $CONTAINER_NAME \
        --restart always \
        -p ${PORT}:3000 \
        -e TZ=Asia/Shanghai \
        -v ${DATA_DIR}:/data \
        $IMAGE_NAME

    save_config
    echo -e "${GREEN}服务已部署并启动${RESET}"
    echo -e "${GREEN}访问地址: http://$(get_ip):${PORT}${RESET}"
}

start_service() {
    docker start $CONTAINER_NAME
    echo -e "${GREEN}服务已启动${RESET}"
}

stop_service() {
    docker stop $CONTAINER_NAME
    echo -e "${GREEN}服务已停止${RESET}"
}

restart_service() {
    docker restart $CONTAINER_NAME
    echo -e "${GREEN}服务已重启${RESET}"
}

update_service() {
    echo -e "${GREEN}正在拉取最新镜像...${RESET}"
    docker pull $IMAGE_NAME
    docker stop $CONTAINER_NAME || true
    docker rm $CONTAINER_NAME || true

    load_config
    docker run -d \
        --name $CONTAINER_NAME \
        --restart always \
        -p ${PORT}:3000 \
        -e TZ=Asia/Shanghai \
        -v ${DATA_DIR}:/data \
        $IMAGE_NAME

    echo -e "${GREEN}镜像已更新并重启服务${RESET}"
}

logs_service() {
    docker logs -f $CONTAINER_NAME
}

enter_service() {
    docker exec -it $CONTAINER_NAME /bin/sh
}

remove_service() {
    echo -e "${GREEN}警告: 将删除容器和数据！是否继续？(y/n)${RESET}"
    read confirm
    if [ "$confirm" == "y" ]; then
        docker stop $CONTAINER_NAME || true
        docker rm $CONTAINER_NAME || true
        rm -rf "$WORKDIR"
        echo -e "${GREEN}容器和数据已删除${RESET}"
    else
        echo "已取消操作"
    fi
}

show_config() {
    load_config
    echo -e "${GREEN}当前配置:${RESET}"
    echo -e "${GREEN}  访问地址: http://$(get_ip):${PORT}${RESET}"
    echo -e "${GREEN}  数据目录: ${DATA_DIR}${RESET}"
}

# ================== 菜单 ==================
menu() {
    clear
    echo -e "${GREEN}====== NewAPI 一键管理菜单 ======${RESET}"
    echo -e "${GREEN}1. 部署并启动服务 (自定义端口/目录)${RESET}"
    echo -e "${GREEN}2. 启动服务${RESET}"
    echo -e "${GREEN}3. 停止服务${RESET}"
    echo -e "${GREEN}4. 重启服务${RESET}"
    echo -e "${GREEN}5. 更新镜像并重启服务${RESET}"
    echo -e "${GREEN}6. 查看日志${RESET}"
    echo -e "${GREEN}7. 进入容器${RESET}"
    echo -e "${GREEN}8. 删除容器和数据${RESET}"
    echo -e "${GREEN}9. 查看当前配置${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo "================================="
}

# ================== 主循环 ==================
check_env
while true; do
    menu
    read -p "请选择操作: " choice
    case $choice in
        1) deploy_service ;;
        2) start_service ;;
        3) stop_service ;;
        4) restart_service ;;
        5) update_service ;;
        6) logs_service ;;
        7) enter_service ;;
        8) remove_service ;;
        9) show_config ;;
        0) exit 0 ;;
        *) echo -e "${GREEN}无效选项${RESET}" ;;
    esac
    read -p "按回车键返回菜单..."
done
