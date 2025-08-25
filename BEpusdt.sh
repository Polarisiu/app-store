#!/bin/bash

# ================== 颜色 ==================
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

CONTAINER_NAME="bepusdt"
IMAGE_NAME="v03413/bepusdt:latest"

# 默认路径
DEFAULT_CONF_PATH="/root/bepusdt/conf.toml"
DEFAULT_DB_PATH="/root/bepusdt/sqlite.db"

# ================== 检查 root ==================
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 用户运行此脚本！${RESET}"
    exit 1
fi

# ================== 函数 ==================

check_port() {
    local port=$1
    while lsof -i :"$port" >/dev/null 2>&1; do
        echo -e "${YELLOW}端口 $port 已被占用，请输入新的端口 [默认: $port]: ${RESET}"
        read new_port
        port=${new_port:-$port}
    done
    echo $port
}

start_container() {
    read -p "请输入宿主机 conf.toml 配置文件路径 [默认: ${DEFAULT_CONF_PATH}]: " CONF_PATH
    CONF_PATH=${CONF_PATH:-$DEFAULT_CONF_PATH}

    read -p "请输入宿主机数据库文件路径 [默认: ${DEFAULT_DB_PATH}]: " DB_PATH
    DB_PATH=${DB_PATH:-$DEFAULT_DB_PATH}

    read -p "请输入宿主机映射端口 [默认: 8080]: " PORT
    PORT=${PORT:-8080}
    PORT=$(check_port $PORT)

    if [ ! -f "$CONF_PATH" ]; then
        echo -e "${RED}配置文件不存在: $CONF_PATH${RESET}"
        return
    fi

    if [ ! -f "$DB_PATH" ]; then
        echo -e "${YELLOW}数据库文件不存在，启动后容器会自动创建: $DB_PATH${RESET}"
    fi

    if [ "$(docker ps -a -q -f name=^/${CONTAINER_NAME}$)" ]; then
        docker restart ${CONTAINER_NAME} && echo -e "${GREEN}容器已重启${RESET}"
    else
        docker run -d --name ${CONTAINER_NAME} --restart=unless-stopped \
        -p ${PORT}:8080 \
        -v ${CONF_PATH}:/usr/local/bepusdt/conf.toml \
        -v ${DB_PATH}:/var/lib/bepusdt/sqlite.db \
        ${IMAGE_NAME}

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}容器已启动成功！端口: ${PORT}${RESET}"
        else
            echo -e "${RED}容器启动失败，请检查配置！${RESET}"
        fi
    fi
}

stop_container() {
    if docker ps -a -q -f name=^/${CONTAINER_NAME}$ >/dev/null; then
        docker stop ${CONTAINER_NAME} && echo -e "${GREEN}容器已停止${RESET}"
    else
        echo -e "${YELLOW}容器 ${CONTAINER_NAME} 不存在${RESET}"
    fi
}

restart_container() {
    if docker ps -a -q -f name=^/${CONTAINER_NAME}$ >/dev/null; then
        docker restart ${CONTAINER_NAME} && echo -e "${GREEN}容器已重启${RESET}"
    else
        echo -e "${YELLOW}容器 ${CONTAINER_NAME} 不存在${RESET}"
    fi
}

remove_container() {
    DB_PATH=${DB_PATH:-$DEFAULT_DB_PATH}
    if [ "$(docker ps -a -q -f name=^/${CONTAINER_NAME}$)" ]; then
        read -p "确认删除容器 ${CONTAINER_NAME} 并删除挂载的数据库文件吗？[y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            docker rm -f ${CONTAINER_NAME} && echo -e "${GREEN}容器已删除${RESET}"
            if [ -f "$DB_PATH" ]; then
                rm -f "$DB_PATH" && echo -e "${GREEN}数据库文件已删除: $DB_PATH${RESET}"
            fi
        else
            echo "取消删除操作，返回菜单"
        fi
    else
        echo -e "${YELLOW}容器 ${CONTAINER_NAME} 不存在，返回菜单${RESET}"
    fi
}

update_container() {
    echo -e "${GREEN}开始拉取最新镜像...${RESET}"
    docker pull ${IMAGE_NAME}

    if [ "$(docker ps -a -q -f name=^/${CONTAINER_NAME}$)" ]; then
        docker restart ${CONTAINER_NAME} && echo -e "${GREEN}容器已更新并重启成功${RESET}"
    else
        echo -e "${YELLOW}容器 ${CONTAINER_NAME} 不存在，无法重启，请先启动容器${RESET}"
    fi
}

logs_container() {
    if [ "$(docker ps -a -q -f name=^/${CONTAINER_NAME}$)" ]; then
        read -p "输入查看日志行数，默认显示最近 100 行: " LINES
        LINES=${LINES:-100}
        docker logs --tail $LINES -f ${CONTAINER_NAME}
    else
        echo -e "${YELLOW}容器 ${CONTAINER_NAME} 不存在，无法查看日志${RESET}"
    fi
}

status_container() {
    if docker ps -a -q -f name=${CONTAINER_NAME} >/dev/null; then
        docker ps -a --filter "name=${CONTAINER_NAME}"
    else
        echo -e "${YELLOW}容器 ${CONTAINER_NAME} 不存在${RESET}"
    fi
}

# ================== 菜单 ==================
while true; do
    echo -e "\n${GREEN}====== BEPUSDT 容器管理 ======${RESET}"
    echo -e "${GREEN}1) 启动容器${RESET}"
    echo -e "${GREEN}2) 停止容器${RESET}"
    echo -e "${GREEN}3) 重启容器${RESET}"
    echo -e "${GREEN}4) 删除容器${RESET}"
    echo -e "${GREEN}5) 查看状态${RESET}"
    echo -e "${GREEN}6) 更新容器${RESET}"
    echo -e "${GREEN}7) 查看日志${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "请选择操作: " choice

    case $choice in
        1) start_container ;;
        2) stop_container ;;
        3) restart_container ;;
        4) remove_container ;;
        5) status_container ;;
        6) update_container ;;
        7) logs_container ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择，返回菜单${RESET}" ;;
    esac
done
