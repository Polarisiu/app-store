#!/bin/bash

IMAGE_NAME="musicdown-web"
CONTAINER_NAME="musicdown"
HOST_PORT=8000
DOWNLOAD_DIR="$PWD/downloads"
COLOR_GREEN="\033[32m"
COLOR_RESET="\033[0m"

# 获取公网 IP
get_ip() {
    curl -s ifconfig.me || curl -s ip.sb || echo "127.0.0.1"
}

menu() {
    clear
    echo -e "${COLOR_GREEN}============================${COLOR_RESET}"
    echo -e "${COLOR_GREEN}   音乐下载器网页 管理菜单   ${COLOR_RESET}"
    echo -e "${COLOR_GREEN}============================${COLOR_RESET}"
    echo -e "${COLOR_GREEN}1.${COLOR_RESET} 构建/更新 Docker 镜像"
    echo -e "${COLOR_GREEN}2.${COLOR_RESET} 启动容器 (默认模式)"
    echo -e "${COLOR_GREEN}3.${COLOR_RESET} 启动容器 (轻量下载模式)"
    echo -e "${COLOR_GREEN}4.${COLOR_RESET} 停止容器"
    echo -e "${COLOR_GREEN}5.${COLOR_RESET} 重启容器"
    echo -e "${COLOR_GREEN}6.${COLOR_RESET} 查看日志"
    echo -e "${COLOR_GREEN}7.${COLOR_RESET} 删除容器和镜像"
    echo -e "${COLOR_GREEN}0.${COLOR_RESET} 退出"
    echo -e "${COLOR_GREEN}============================${COLOR_RESET}"
}

set_custom_config() {
    read -p "请输入映射端口 (默认 8000): " input_port
    if [ -n "$input_port" ]; then
        HOST_PORT=$input_port
    fi

    read -p "请输入下载目录路径 (默认 $DOWNLOAD_DIR): " input_path
    if [ -n "$input_path" ]; then
        DOWNLOAD_DIR=$input_path
    fi

    mkdir -p "$DOWNLOAD_DIR"
}

check_container() {
    if [ "$(docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
        if [ "$(docker ps -q -f name=^${CONTAINER_NAME}$)" ]; then
            echo -e "${COLOR_GREEN}容器 ${CONTAINER_NAME} 已在运行 (端口: $HOST_PORT)${COLOR_RESET}"
            echo -e "${COLOR_GREEN}访问: http://$(get_ip):$HOST_PORT${COLOR_RESET}"
            return 1
        else
            echo -e "${COLOR_GREEN}容器 ${CONTAINER_NAME} 存在但未运行${COLOR_RESET}"
            read -p "是否要重新启动它？(y/n): " ans
            if [ "$ans" = "y" ]; then
                docker start $CONTAINER_NAME
                echo -e "${COLOR_GREEN}容器已重新启动，访问: http://$(get_ip):$HOST_PORT${COLOR_RESET}"
            fi
            return 1
        fi
    fi
    return 0
}

build_image() {
    echo -e "${COLOR_GREEN}正在构建镜像...${COLOR_RESET}"
    docker build -t $IMAGE_NAME .
}

start_container() {
    check_container || return
    set_custom_config
    echo -e "${COLOR_GREEN}正在启动容器...${COLOR_RESET}"
    docker run -d --name $CONTAINER_NAME \
        -p $HOST_PORT:8000 \
        -v $DOWNLOAD_DIR:/app/downloads \
        $IMAGE_NAME
    echo -e "${COLOR_GREEN}容器已启动，访问: http://$(get_ip):$HOST_PORT${COLOR_RESET}"
    echo -e "${COLOR_GREEN}下载目录: $DOWNLOAD_DIR${COLOR_RESET}"
}

start_light_container() {
    check_container || return
    set_custom_config
    echo -e "${COLOR_GREEN}正在启动容器 (轻量下载模式)...${COLOR_RESET}"
    docker run -d --name $CONTAINER_NAME \
        -p $HOST_PORT:8000 \
        -v $DOWNLOAD_DIR:/app/downloads \
        -e USE_LIGHT_DOWNLOAD_MODE=true \
        $IMAGE_NAME
    echo -e "${COLOR_GREEN}容器已启动，访问: http://$(get_ip):$HOST_PORT${COLOR_RESET}"
    echo -e "${COLOR_GREEN}下载目录: $DOWNLOAD_DIR${COLOR_RESET}"
}

stop_container() {
    if [ "$(docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
        docker stop $CONTAINER_NAME >/dev/null 2>&1
        docker rm $CONTAINER_NAME >/dev/null 2>&1
        echo -e "${COLOR_GREEN}容器已停止并删除${COLOR_RESET}"
    else
        echo -e "${COLOR_GREEN}没有找到容器 ${CONTAINER_NAME}${COLOR_RESET}"
    fi
}

restart_container() {
    stop_container
    start_container
}

view_logs() {
    if [ "$(docker ps -aq -f name=^${CONTAINER_NAME}$)" ]; then
        docker logs -f $CONTAINER_NAME
    else
        echo -e "${COLOR_GREEN}容器 ${CONTAINER_NAME} 不存在${COLOR_RESET}"
    fi
}

remove_all() {
    stop_container
    docker rmi $IMAGE_NAME -f
    echo -e "${COLOR_GREEN}容器和镜像已删除${COLOR_RESET}"
}

while true; do
    menu
    read -p "请输入选项: " choice
    case $choice in
        1) build_image ;;
        2) start_container ;;
        3) start_light_container ;;
        4) stop_container ;;
        5) restart_container ;;
        6) view_logs ;;
        7) remove_all ;;
        0) exit 0 ;;
        *) echo -e "${COLOR_GREEN}无效选项${COLOR_RESET}" ;;
    esac
    echo -e "${COLOR_GREEN}按回车键继续...${COLOR_RESET}"
    read
done
