#!/bin/bash

# ==============================
# LRCAPI Docker 管理菜单（首次运行可输入自定义配置 + 更新功能）
# ==============================

CONFIG_FILE="$HOME/lrcapi_config.conf"

# 颜色
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ---------- 初始化配置 ----------
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}首次运行，请输入容器配置信息:${RESET}"
    read -rp "容器名称 (默认 lrcapi): " CONTAINER_NAME
    CONTAINER_NAME=${CONTAINER_NAME:-lrcapi}

    read -rp "镜像名称 (默认 hisatri/lrcapi:latest): " IMAGE_NAME
    IMAGE_NAME=${IMAGE_NAME:-hisatri/lrcapi:latest}

    read -rp "宿主机音乐目录 (默认 $HOME/music): " MUSIC_DIR
    MUSIC_DIR=${MUSIC_DIR:-$HOME/music}

    read -rp "宿主机端口 (默认 28883): " HOST_PORT
    HOST_PORT=${HOST_PORT:-28883}

    CONTAINER_MUSIC_DIR="/music"

    # 保存到配置文件
    cat > "$CONFIG_FILE" <<EOL
CONTAINER_NAME="$CONTAINER_NAME"
IMAGE_NAME="$IMAGE_NAME"
MUSIC_DIR="$MUSIC_DIR"
HOST_PORT="$HOST_PORT"
CONTAINER_MUSIC_DIR="$CONTAINER_MUSIC_DIR"
EOL

    echo -e "${GREEN}配置已保存到 $CONFIG_FILE${RESET}"
fi

# 加载配置
source "$CONFIG_FILE"

# ---------- 功能函数 ----------
start_container() {
    mkdir -p "$MUSIC_DIR"  # 确保音乐目录存在
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo -e "${YELLOW}容器已经在运行！${RESET}"
    else
        if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
            echo -e "${GREEN}检测到已存在的容器，启动中...${RESET}"
            docker start $CONTAINER_NAME
        else
            echo -e "${GREEN}创建并启动新容器...${RESET}"
            docker run -d \
                --name $CONTAINER_NAME \
                -p $HOST_PORT:$HOST_PORT \
                -v $MUSIC_DIR:$CONTAINER_MUSIC_DIR \
                $IMAGE_NAME
        fi
        echo -e "${GREEN}启动完成！访问：http://localhost:$HOST_PORT${RESET}"
    fi
}

stop_container() {
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        docker stop $CONTAINER_NAME
        echo -e "${GREEN}容器已停止${RESET}"
    else
        echo -e "${YELLOW}容器未在运行${RESET}"
    fi
}

restart_container() {
    stop_container
    start_container
}

logs_container() {
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        docker logs -f $CONTAINER_NAME
    else
        echo -e "${RED}容器不存在${RESET}"
    fi
}

delete_container() {
    if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        docker rm -f $CONTAINER_NAME
        echo -e "${GREEN}容器已删除${RESET}"
    else
        echo -e "${YELLOW}容器不存在${RESET}"
    fi
}

edit_config() {
    echo -e "${GREEN}编辑配置文件：$CONFIG_FILE${RESET}"
    nano "$CONFIG_FILE"
    source "$CONFIG_FILE"
    echo -e "${GREEN}配置已更新！${RESET}"
}

update_container() {
    echo -e "${GREEN}拉取最新镜像：$IMAGE_NAME${RESET}"
    docker pull $IMAGE_NAME
    echo -e "${GREEN}停止并删除旧容器...${RESET}"
    stop_container
    delete_container
    echo -e "${GREEN}使用最新镜像启动容器...${RESET}"
    start_container
    echo -e "${GREEN}更新完成！${RESET}"
}

# ---------- 菜单 ----------
while true; do
    echo -e "${GREEN}=== LRCAPI Docker 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 启动容器${RESET}"
    echo -e "${GREEN}2) 停止容器${RESET}"
    echo -e "${GREEN}3) 重启容器${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 删除容器${RESET}"
    echo -e "${GREEN}6) 编辑配置${RESET}"
    echo -e "${GREEN}7) 更新镜像并重建容器${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -rp "请选择操作: " choice

    case $choice in
        1) start_container ;;
        2) stop_container ;;
        3) restart_container ;;
        4) logs_container ;;
        5) delete_container ;;
        6) edit_config ;;
        7) update_container ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
done
