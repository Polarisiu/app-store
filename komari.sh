#!/bin/bash

# ================== 颜色定义 ==================
green="\033[32m"
red="\033[31m"
yellow="\033[33m"
re="\033[0m"

# ================== 配置 ==================
IMAGE_NAME="ghcr.io/komari-monitor/komari:latest"
CONTAINER_NAME="komari"
CONFIG_FILE="/root/komari.env"
DATA_DIR="$(pwd)/data"

# ================== Docker 安装 ==================
install_docker() {
    if command -v docker >/dev/null 2>&1; then
        echo -e "${green}✅ Docker 已安装${re}"
        return
    fi
    echo -e "${yellow}⚠️ 未检测到 Docker，正在安装...${re}"
    if [ -f /etc/alpine-release ]; then
        apk update
        apk add docker openrc
        rc-update add docker boot
        service docker start
    elif [ -f /etc/debian_version ]; then
        apt update -y
        apt install -y curl apt-transport-https ca-certificates software-properties-common gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -
        add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
        apt update -y
        apt install -y docker-ce docker-ce-cli containerd.io
        systemctl enable docker
        systemctl start docker
    elif [ -f /etc/redhat-release ]; then
        yum install -y yum-utils
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
        systemctl enable docker
        systemctl start docker
    else
        echo -e "${red}❌ 系统不支持自动安装 Docker，请手动安装${re}"
        exit 1
    fi
    echo -e "${green}✅ Docker 安装完成${re}"
}

# ================== 保存配置 ==================
save_config() {
    cat > "$CONFIG_FILE" <<EOF
ADMIN_USERNAME="$ADMIN_USERNAME"
ADMIN_PASSWORD="$ADMIN_PASSWORD"
PORT=$PORT
EOF
}

# ================== 加载配置 ==================
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    else
        ADMIN_USERNAME=""
        ADMIN_PASSWORD=""
        PORT=25774
    fi
}

# ================== 工具函数 ==================
get_status() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            echo "运行中"
        else
            echo "已停止"
        fi
    else
        echo "未安装"
    fi
}

check_nat_available() {
    command -v iptables >/dev/null 2>&1 || return 1
    iptables -t nat -L >/dev/null 2>&1 || return 1
    iptables -t nat -L DOCKER >/dev/null 2>&1 || return 1
    return 0
}

# ================== 启动函数 ==================
start_komari() {
    # 先检查是否已有配置，没有就提示输入
    if [ -z "$ADMIN_USERNAME" ] || [ -z "$ADMIN_PASSWORD" ]; then
        echo -e "${yellow}首次安装，请设置管理员账号、密码和端口号${re}"
        read -p "请输入管理员账号: " ADMIN_USERNAME
        read -sp "请输入管理员密码: " ADMIN_PASSWORD
        echo
        read -p "请输入端口号 (默认 25774): " PORT
        if [[ -z "$PORT" || ! "$PORT" =~ ^[0-9]+$ || $PORT -lt 1024 || $PORT -gt 65535 ]]; then
            PORT=25774
        fi
        save_config
        echo -e "${green}✅ 管理员账号、密码和端口已保存${re}"
    fi

    install_docker
    mkdir -p "$DATA_DIR"

    stop_komari >/dev/null 2>&1
    echo -e "${yellow}正在启动 Komari...${re}"

    docker image inspect ${IMAGE_NAME} >/dev/null 2>&1 || docker pull ${IMAGE_NAME}

    if check_nat_available; then
        docker run -d --name ${CONTAINER_NAME} \
            -p ${PORT}:25774 \
            -v ${DATA_DIR}:/app/data \
            -e ADMIN_USERNAME="${ADMIN_USERNAME}" \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
            --restart unless-stopped \
            ${IMAGE_NAME}
        MODE="端口映射"
    else
        docker run -d --name ${CONTAINER_NAME} \
            --network host \
            -v ${DATA_DIR}:/app/data \
            -e ADMIN_USERNAME="${ADMIN_USERNAME}" \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
            --restart unless-stopped \
            ${IMAGE_NAME}
        MODE="host 网络"
    fi

    if [ $? -eq 0 ]; then
        echo -e "${green}✅ Komari 已启动${re}"
        echo "访问地址: http://$(curl -s ifconfig.me):${PORT} （${MODE} 模式）"
    else
        echo -e "${red}❌ 启动失败，请检查镜像或网络${re}"
    fi
}

stop_komari() {
    docker stop ${CONTAINER_NAME} >/dev/null 2>&1
    echo -e "${green}🛑 Komari 已停止${re}"
}

restart_komari() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${yellow}正在重启 Komari...${re}"
        docker restart ${CONTAINER_NAME}
        echo -e "${green}✅ Komari 已重启${re}"
    else
        echo -e "${yellow}容器不存在，正在启动...${re}"
        start_komari
    fi
}

update_komari() {
    echo -e "${yellow}正在拉取最新镜像...${re}"
    docker pull ${IMAGE_NAME}

    echo -e "${yellow}正在删除旧容器...${re}"
    docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1 || true

    echo -e "${yellow}正在重新创建容器...${re}"
    if check_nat_available; then
        docker run -d --name ${CONTAINER_NAME} \
            -p ${PORT}:25774 \
            -v ${DATA_DIR}:/app/data \
            -e ADMIN_USERNAME="${ADMIN_USERNAME}" \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
            --restart unless-stopped \
            ${IMAGE_NAME}
        MODE="端口映射"
    else
        docker run -d --name ${CONTAINER_NAME} \
            --network host \
            -v ${DATA_DIR}:/app/data \
            -e ADMIN_USERNAME="${ADMIN_USERNAME}" \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
            --restart unless-stopped \
            ${IMAGE_NAME}
        MODE="host 网络"
    fi

    if [ $? -eq 0 ]; then
        echo -e "${green}✅ Komari 已更新并启动成功${re}"
        echo "访问地址: http://$(curl -s ifconfig.me):${PORT} （${MODE} 模式）"
    else
        echo -e "${red}❌ 更新失败，请检查镜像或网络${re}"
    fi
}


uninstall_komari() {
    stop_komari
    read -p "是否删除数据目录 ${DATA_DIR}? (y/N): " deldata
    if [[ "$deldata" =~ ^[Yy]$ ]]; then
        rm -rf "$DATA_DIR"
    fi
    docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1
    docker rmi ${IMAGE_NAME} >/dev/null 2>&1
    rm -f "$CONFIG_FILE"
    echo -e "${green}✅ Komari 已卸载${re}"
    ADMIN_USERNAME=""
    ADMIN_PASSWORD=""
}

show_logs() {
    docker logs -f --tail 100 ${CONTAINER_NAME}
}

# ================== 主程序 ==================
load_config
while true; do
    echo -e "\n${green}===== Komari Docker 管理脚本 =====${re}"
    echo -e "${green}容器状态: $(get_status)${re}"
    echo -e "${green}当前端口: $PORT${re}"
    echo -e "${green}管理员账号: ${ADMIN_USERNAME:-未设置}${re}"
    echo -e "${green}管理员密码: ${ADMIN_PASSWORD:-未设置}${re}"
    echo -e "${green}=================================${re}"
    echo -e "${green}1.安装/启动 Komari${re}"
    echo -e "${green}2.停止 Komari${re}"
    echo -e "${green}3.重启 Komari${re}"
    echo -e "${green}4.查看日志${re}"
    echo -e "${green}5.更新 Komari${re}"
    echo -e "${green}6.卸载 Komari${re}"
    echo -e "${green}7.退出${re}"
    echo -e "${green}=================================${re}"

    read -p "请选择操作 [1-7]: " choice

    case $choice in
        1) start_komari ;;
        2) stop_komari ;;
        3) restart_komari ;;
        4) show_logs ;;
        5) update_komari ;;
        6) uninstall_komari ;;
        7) exit 0 ;;
        *) echo -e "${red}无效选项${re}" ;;
    esac
    read -p "按回车键返回菜单..."
done
