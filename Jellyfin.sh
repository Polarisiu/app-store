#!/bin/bash
# Jellyfin 一键部署与更新菜单脚本（绿色菜单、强制root、显示公网IP）

GREEN='\033[0;32m'
RESET='\033[0m'

DEFAULT_CONTAINER_NAME="jellyfin"
DEFAULT_DATA_DIR="$HOME/jellyfin"
DEFAULT_HTTP_PORT="8096"
IMAGE_NAME="jellyfin/jellyfin:latest"
CONFIG_FILE="$HOME/.jellyfin_config"

CONTAINER_NAME=""
DATA_DIR=""
HTTP_PORT=""

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${GREEN}错误: Docker 未安装，请先安装 Docker${RESET}"
        exit 1
    fi
}

get_public_ip() {
    PUBLIC_IP=$(curl -s https://ipinfo.io/ip)
    if ! [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        PUBLIC_IP=$(curl -s https://ifconfig.me/ip)
    fi
    if ! [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        PUBLIC_IP=""
    fi
    echo "$PUBLIC_IP"
}

load_or_input_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    read -p "请输入容器名 [${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}]: " input_container
    CONTAINER_NAME=${input_container:-${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}}

    read -p "请输入统一存放目录（配置+媒体+缓存） [${DATA_DIR:-$DEFAULT_DATA_DIR}]: " input_dir
    DATA_DIR=${input_dir:-${DATA_DIR:-$DEFAULT_DATA_DIR}}

    read -p "请输入宿主机 HTTP 映射端口 [${HTTP_PORT:-$DEFAULT_HTTP_PORT}]: " input_port
    HTTP_PORT=${input_port:-${HTTP_PORT:-$DEFAULT_HTTP_PORT}}

    echo "CONTAINER_NAME=\"$CONTAINER_NAME\"" > "$CONFIG_FILE"
    echo "DATA_DIR=\"$DATA_DIR\"" >> "$CONFIG_FILE"
    echo "HTTP_PORT=\"$HTTP_PORT\"" >> "$CONFIG_FILE"
}

create_dirs() {
    mkdir -p "$DATA_DIR/config" "$DATA_DIR/cache" "$DATA_DIR/media"
    echo -e "${GREEN}已创建数据目录: $DATA_DIR${RESET}"
    chmod -R 755 "$DATA_DIR"
}

deploy_jellyfin() {
    load_or_input_config
    create_dirs
    echo -e "${GREEN}正在部署 Jellyfin 容器...${RESET}"

    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -e TZ=Asia/Shanghai \
        -e UID=0 \
        -e GID=0 \
        -e GIDLIST=0 \
        -p $HTTP_PORT:8096 \
        -p 8920:8920 \
        -v $DATA_DIR/config:/config \
        -v $DATA_DIR/cache:/cache \
        -v $DATA_DIR/media:/media \
        $IMAGE_NAME

    PUBLIC_IP=$(get_public_ip)
    if [[ $PUBLIC_IP != "无法获取公网 IP" ]]; then
        echo -e "${GREEN}部署完成！公网访问地址: http://${PUBLIC_IP}:${HTTP_PORT}${RESET}"
    else
        echo -e "${GREEN}部署完成，但未能获取公网 IP，请使用内网访问${RESET}"
    fi
}

start_jellyfin() { docker start $CONTAINER_NAME && echo -e "${GREEN}容器已启动${RESET}"; }
stop_jellyfin() { docker stop $CONTAINER_NAME && echo -e "${GREEN}容器已停止${RESET}"; }
remove_jellyfin() { docker rm -f $CONTAINER_NAME && echo -e "${GREEN}容器已删除${RESET}"; }
view_logs() { docker logs -f $CONTAINER_NAME; }

uninstall_all() {
    stop_jellyfin
    remove_jellyfin
    if [ -n "$DATA_DIR" ] && [ -d "$DATA_DIR" ]; then
        read -p "确定要删除 $DATA_DIR 吗？此操作不可恢复 [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf "$DATA_DIR"
            echo -e "${GREEN}数据目录已删除${RESET}"
        fi
    fi
    [ -f "$CONFIG_FILE" ] && rm -f "$CONFIG_FILE" && echo -e "${GREEN}配置文件已删除${RESET}"
}

update_image() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        echo -e "${GREEN}配置文件不存在，请先部署容器${RESET}"
        exit 1
    fi

    echo -e "${GREEN}正在拉取最新镜像: $IMAGE_NAME ...${RESET}"
    docker pull $IMAGE_NAME

    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo -e "${GREEN}停止正在运行的容器...${RESET}"
        docker stop $CONTAINER_NAME
    fi

    if [ "$(docker ps -a -q -f name=$CONTAINER_NAME)" ]; then
        echo -e "${GREEN}删除旧容器（保留数据）...${RESET}"
        docker rm $CONTAINER_NAME
    fi

    echo -e "${GREEN}使用最新镜像重启容器...${RESET}"
    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -e TZ=Asia/Shanghai \
        -e UID=0 \
        -e GID=0 \
        -e GIDLIST=0 \
        -p $HTTP_PORT:8096 \
        -p 8920:8920 \
        -v $DATA_DIR/config:/config \
        -v $DATA_DIR/cache:/cache \
        -v $DATA_DIR/media:/media \
        $IMAGE_NAME

    PUBLIC_IP=$(get_public_ip)
    if [[ $PUBLIC_IP != "无法获取公网 IP" ]]; then
        echo -e "${GREEN}更新完成！公网访问地址: http://${PUBLIC_IP}:${HTTP_PORT}${RESET}"
    else
        echo -e "${GREEN}更新完成，但未能获取公网 IP，请使用内网访问${RESET}"
    fi
}

show_menu() {
    echo -e "${GREEN}===== Jellyfin 一键部署与更新菜单 =====${RESET}"
    echo -e "${GREEN}1. 部署 Jellyfin${RESET}"
    echo -e "${GREEN}2. 启动容器${RESET}"
    echo -e "${GREEN}3. 停止容器${RESET}"
    echo -e "${GREEN}4. 删除容器${RESET}"
    echo -e "${GREEN}5. 查看日志${RESET}"
    echo -e "${GREEN}6. 卸载全部数据（容器+目录+配置文件）${RESET}"
    echo -e "${GREEN}7. 更新镜像并重启容器${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -n "请输入编号: "
}

check_docker

while true; do
    show_menu
    read choice
    case $choice in
        1) deploy_jellyfin ;;
        2) start_jellyfin ;;
        3) stop_jellyfin ;;
        4) remove_jellyfin ;;
        5) view_logs ;;
        6) uninstall_all ;;
        7) update_image ;;
        0) echo "退出脚本"; exit 0 ;;
        *) echo -e "${GREEN}无效选项${RESET}" ;;
    esac
done
