#!/bin/bash
set -e

# ================== 配置 ==================
IMAGE="helloz/onenav"
CONTAINER="onenav"
DEFAULT_PORT=3080
DATA_DIR="/data/onenav"

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

# ================== 公共函数 ==================
get_ip() {
    ip addr show | awk '/inet / && !/127.0.0.1/ {print $2}' | cut -d/ -f1 | head -n1
}

# ================== 功能函数 ==================
install() {
    read -p "请输入映射端口(默认:${DEFAULT_PORT}): " port
    port=${port:-$DEFAULT_PORT}

    echo -e "${GREEN}>>> 正在部署 OneNav 容器，端口: ${port}${RESET}"
    docker run -itd --name $CONTAINER \
        -p ${port}:80 \
        -v ${DATA_DIR}:/data/wwwroot/default/data \
        --restart always \
        $IMAGE

    local ip=$(get_ip)
    echo -e "${GREEN}OneNav 已部署完成，访问: http://${ip}:${port}${RESET}"
}

start() {
    docker start $CONTAINER && echo -e "${GREEN}OneNav 已启动${RESET}"
}

stop() {
    docker stop $CONTAINER && echo -e "${GREEN}OneNav 已停止${RESET}"
}

restart() {
    docker restart $CONTAINER && echo -e "${GREEN}OneNav 已重启${RESET}"
}

status() {
    docker ps -a | grep $CONTAINER || echo -e "${GREEN}容器不存在${RESET}"
}

logs() {
    docker logs -f $CONTAINER
}

enter() {
    docker exec -it $CONTAINER /bin/sh
}

remove() {
    echo -e "${GREEN}!!! 删除操作 !!!${RESET}"
    read -p "是否删除容器和全部数据？(y=删除容器+数据 / n=只删除容器): " c
    if [ "$c" = "y" ]; then
        docker rm -f $CONTAINER 2>/dev/null || true
        rm -rf ${DATA_DIR}
        echo -e "${GREEN}OneNav 容器和全部数据已删除${RESET}"
    else
        docker rm -f $CONTAINER 2>/dev/null || true
        echo -e "${GREEN}OneNav 容器已删除，数据已保留${RESET}"
    fi
}

update() {
    echo -e "${GREEN}>>> 正在拉取最新 OneNav 镜像...${RESET}"
    docker pull $IMAGE

    echo -e "${GREEN}>>> 重启容器以应用最新镜像...${RESET}"
    docker stop $CONTAINER
    docker start $CONTAINER

    local ip=$(get_ip)
    local port=$(docker inspect --format='{{(index (index .HostConfig.PortBindings "80/tcp") 0).HostPort}}' $CONTAINER)

    echo -e "${GREEN}OneNav 已更新并重启完成${RESET}"
    echo -e "${GREEN}访问地址: http://${ip}:${port}${RESET}"
}

# ================== 菜单 ==================
menu() {
    echo -e "${GREEN}========= OneNav 容器管理 =========${RESET}"
    echo -e "${GREEN}1. 部署 OneNav${RESET}"
    echo -e "${GREEN}2. 启动${RESET}"
    echo -e "${GREEN}3. 停止${RESET}"
    echo -e "${GREEN}4. 重启${RESET}"
    echo -e "${GREEN}5. 查看状态${RESET}"
    echo -e "${GREEN}6. 查看日志${RESET}"
    echo -e "${GREEN}7. 进入容器${RESET}"
    echo -e "${GREEN}8. 删除容器${RESET}"
    echo -e "${GREEN}9. 更新容器${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "================================"
    read -p "请输入选项: " opt
    case $opt in
        1) install ;;
        2) start ;;
        3) stop ;;
        4) restart ;;
        5) status ;;
        6) logs ;;
        7) enter ;;
        8) remove ;;
        9) update ;;
        0) exit 0 ;;
        *) echo "无效选项" ;;
    esac
    sleep 2
    menu
}

menu
