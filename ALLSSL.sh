#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ================== 容器配置 ==================
CONTAINER_NAME="allinssl"
IMAGE_NAME="allinssl/allinssl:latest"
HOST_PORT=7979
CONTAINER_PORT=8888
DATA_DIR="/www/allinssl/data"
USERNAME="allinssl"
PASSWORD="allinssldocker"
URL="allinssl"

# ================== 函数定义 ==================
check_port() {
    if lsof -i:$HOST_PORT >/dev/null 2>&1; then
        echo -e "${RED}端口 $HOST_PORT 已被占用，请修改 HOST_PORT 后重试！${RESET}"
        exit 1
    fi
}

install_container() {
    check_port
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}容器已存在，无法重复安装${RESET}"
        return
    fi

    echo -e "${GREEN}开始安装并启动容器...${RESET}"
    docker run -itd \
        --name $CONTAINER_NAME \
        -p $HOST_PORT:$CONTAINER_PORT \
        -v $DATA_DIR:$DATA_DIR \
        -e ALLINSSL_USER=$USERNAME \
        -e ALLINSSL_PWD=$PASSWORD \
        -e ALLINSSL_URL=$URL \
        $IMAGE_NAME

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}容器安装并启动成功！${RESET}"
        show_access_info
    else
        echo -e "${RED}容器安装失败！${RESET}"
    fi
}

start_container() {
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
        echo -e "${GREEN}启动容器...${RESET}"
        docker start $CONTAINER_NAME
        show_access_info
    else
        echo -e "${RED}容器不存在，请先安装！${RESET}"
    fi
}

stop_container() {
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}停止容器...${RESET}"
        docker stop $CONTAINER_NAME
    else
        echo -e "${RED}容器不存在！${RESET}"
    fi
}

remove_container() {
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
        echo -e "${RED}删除容器...${RESET}"
        docker rm -f $CONTAINER_NAME
    else
        echo -e "${RED}容器不存在！${RESET}"
    fi
}

update_container() {
    echo -e "${GREEN}更新容器镜像...${RESET}"
    docker pull $IMAGE_NAME
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
        echo -e "${YELLOW}停止旧容器并删除...${RESET}"
        docker rm -f $CONTAINER_NAME
    fi
    install_container
}

view_logs() {
    if docker ps -a --format '{{.Names}}' | grep -Eq "^${CONTAINER_NAME}$"; then
        echo -e "${GREEN}查看容器日志...${RESET}"
        docker logs -f $CONTAINER_NAME
    else
        echo -e "${RED}容器不存在！${RESET}"
    fi
}

show_access_info() {
    # 本地 IP
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    # 公网 IP（稳定接口）
    PUBLIC_IP=$(curl -s https://api.ipify.org)

    echo -e "${GREEN}================ 访问信息 =================${RESET}"
    echo -e "${GREEN}本地地址: http://$LOCAL_IP:$HOST_PORT${RESET}"
    if [[ -n "$PUBLIC_IP" && "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${GREEN}公网地址: http://$PUBLIC_IP:$HOST_PORT${RESET}"
    else
        echo -e "${RED}无法获取公网 IP${RESET}"
    fi
    echo -e "${GREEN}用户名: $USERNAME${RESET}"
    echo -e "${GREEN}密码:   $PASSWORD${RESET}"
     echo -e "${GREEN}安全入口：allinssl${RESET}"
    echo -e "${GREEN}===========================================${RESET}"
}

show_menu() {
    echo -e "\n${GREEN}================ AllinSSL Docker 管理 =================${RESET}"
    echo -e "${GREEN}1) 安装并启动容器${RESET}"
    echo -e "${GREEN}2) 启动容器${RESET}"
    echo -e "${GREEN}3) 停止容器${RESET}"
    echo -e "${GREEN}4) 删除容器${RESET}"
    echo -e "${GREEN}5) 更新容器${RESET}"
    echo -e "${GREEN}6) 查看日志${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    echo -ne "${GREEN}请选择操作: ${RESET}"
}

# ================== 主循环 ==================
while true; do
    show_menu
    read choice
    case $choice in
        1) install_container ;;
        2) start_container ;;
        3) stop_container ;;
        4) remove_container ;;
        5) update_container ;;
        6) view_logs ;;
        0) echo -e "${GREEN}退出脚本${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新选择！${RESET}" ;;
    esac
done
