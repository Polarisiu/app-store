#!/bin/bash
# EmbyServer 一键部署与更新菜单脚本（绿色菜单、自动检测用户目录）

GREEN='\033[0;32m'
RESET='\033[0m'

# 检测当前用户，如果是 root，则尝试使用普通用户 home
if [ "$EUID" -eq 0 ]; then
    if [ -n "$SUDO_USER" ]; then
        # 使用执行 sudo 的普通用户
        USER_HOME=$(eval echo "~$SUDO_USER")
    else
        # 没有普通用户环境，提示手动修改
        echo -e "${GREEN}警告: 你当前以 root 执行脚本，媒体和配置目录将放在 /root 下。建议用普通用户运行脚本。${RESET}"
        USER_HOME="/root"
    fi
else
    USER_HOME="$HOME"
fi

# 默认配置
DEFAULT_CONTAINER_NAME="emby"
DEFAULT_DATA_DIR="$USER_HOME/emby"
DEFAULT_HTTP_PORT="8096"
IMAGE_NAME="emby/embyserver:latest"
CONFIG_FILE="$USER_HOME/.emby_config"

CONTAINER_NAME=""
DATA_DIR=""
HTTP_PORT=""

# 检查 Docker
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${GREEN}错误: Docker 未安装，请先安装 Docker${RESET}"
        exit 1
    fi
}

# 获取公网 IP
get_public_ip() {
    PUBLIC_IP=$(curl -s --max-time 5 https://ipinfo.io/ip)
    if ! [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        PUBLIC_IP=$(curl -s --max-time 5 https://ifconfig.me/ip)
    fi
    if ! [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        PUBLIC_IP=""
    fi
    echo "$PUBLIC_IP"
}

# 读取或输入配置
load_or_input_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi

    read -p "请输入容器名 [${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}]: " input_container
    CONTAINER_NAME=${input_container:-${CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}}

    read -p "请输入统一存放目录（配置+媒体） [${DATA_DIR:-$DEFAULT_DATA_DIR}]: " input_dir
    DATA_DIR=$(realpath "${input_dir:-${DATA_DIR:-$DEFAULT_DATA_DIR}}")

    read -p "请输入宿主机 HTTP 映射端口 [${HTTP_PORT:-$DEFAULT_HTTP_PORT}]: " input_port
    HTTP_PORT=${input_port:-${HTTP_PORT:-$DEFAULT_HTTP_PORT}}

    # 保存配置
    echo "CONTAINER_NAME=\"$CONTAINER_NAME\"" > "$CONFIG_FILE"
    echo "DATA_DIR=\"$DATA_DIR\"" >> "$CONFIG_FILE"
    echo "HTTP_PORT=\"$HTTP_PORT\"" >> "$CONFIG_FILE"
}

# 创建目录并设置权限
create_dirs() {
    mkdir -p "$DATA_DIR/config" "$DATA_DIR/media"

    # 如果不是 root 执行，给 Emby 默认 UID/GID 权限
    if [ "$EUID" -ne 0 ]; then
        chown -R 1000:1000 "$DATA_DIR"
    fi
    chmod -R 755 "$DATA_DIR"
}

# 部署容器
deploy_emby() {
    load_or_input_config
    create_dirs
    echo -e "${GREEN}正在部署 EmbyServer 容器...${RESET}"

    docker run -d \
        --name $CONTAINER_NAME \
        --restart unless-stopped \
        -e TZ=Asia/Shanghai \
        -p $HTTP_PORT:8096 \
        -p 8920:8920 \
        -v $DATA_DIR/config:/config \
        -v $DATA_DIR/media:/mnt/share1 \
        emby/embyserver:latest

    PUBLIC_IP=$(get_public_ip)
    if [ -n "$PUBLIC_IP" ]; then
        echo -e "${GREEN}部署完成！公网访问地址: http://${PUBLIC_IP}:${HTTP_PORT}${RESET}"
    else
        echo -e "${GREEN}部署完成，请使用内网访问${RESET}"
    fi
}

# 启动/停止/删除/日志
start_emby() { docker start $CONTAINER_NAME && echo -e "${GREEN}容器已启动${RESET}"; }
stop_emby() { docker stop $CONTAINER_NAME && echo -e "${GREEN}容器已停止${RESET}"; }
remove_emby() { docker rm -f $CONTAINER_NAME && echo -e "${GREEN}容器已删除${RESET}"; }
view_logs() { docker logs -f $CONTAINER_NAME; }

# 卸载所有数据
uninstall_all() {
    stop_emby
    remove_emby
    read -p "确定删除 $DATA_DIR 吗？[y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$DATA_DIR"
        echo -e "${GREEN}数据目录已删除${RESET}"
    fi
    [ -f "$CONFIG_FILE" ] && rm -f "$CONFIG_FILE" && echo -e "${GREEN}配置文件已删除${RESET}"
}

# 更新镜像
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
        docker stop $CONTAINER_NAME
    fi

    if [ "$(docker ps -a -q -f name=$CONTAINER_NAME)" ]; then
        docker rm $CONTAINER_NAME
    fi

    deploy_emby
}

# 菜单
show_menu() {
    echo -e "${GREEN}===== EmbyServer 一键部署与更新菜单 =====${RESET}"
    echo -e "${GREEN}1.${RESET} 部署 EmbyServer"
    echo -e "${GREEN}2.${RESET} 启动容器"
    echo -e "${GREEN}3.${RESET} 停止容器"
    echo -e "${GREEN}4.${RESET} 删除容器"
    echo -e "${GREEN}5.${RESET} 查看日志"
    echo -e "${GREEN}6.${RESET} 卸载全部数据（容器+统一目录+配置文件）"
    echo -e "${GREEN}7.${RESET} 更新镜像并重启容器"
    echo -e "${GREEN}0.${RESET} 退出"
    echo -n "请输入编号: "
}

# 主循环
check_docker

while true; do
    show_menu
    read choice
    case $choice in
        1) deploy_emby ;;
        2) start_emby ;;
        3) stop_emby ;;
        4) remove_emby ;;
        5) view_logs ;;
        6) uninstall_all ;;
        7) update_image ;;
        0) echo "退出脚本"; exit 0 ;;
        *) echo -e "${GREEN}无效选项${RESET}" ;;
    esac
done
