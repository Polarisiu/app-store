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

# ================== 配置加载 ==================
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    ADMIN_USERNAME="默认"
    ADMIN_PASSWORD="默认"
    PORT=25774
fi

save_config() {
    cat > "$CONFIG_FILE" <<EOF
ADMIN_USERNAME="$ADMIN_USERNAME"
ADMIN_PASSWORD="$ADMIN_PASSWORD"
PORT=$PORT
EOF
}

# ================== 首次运行初始化 ==================
install_docker

if [ ! -f "$CONFIG_FILE" ] || [ "$ADMIN_USERNAME" = "默认" ] || [ "$ADMIN_PASSWORD" = "默认" ]; then
    echo -e "${yellow}首次运行，请设置管理员账号和密码${re}"
    read -p "请输入管理员账号: " ADMIN_USERNAME
    read -p "请输入管理员密码: " ADMIN_PASSWORD
    save_config
    echo -e "${green}✅ 管理员账号密码已保存${re}"
fi

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
    iptables -t nat -L >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        return 1
    fi
    iptables -t nat -L DOCKER >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        return 1
    fi
    return 0
}

start_komari() {
    stop_komari >/dev/null 2>&1
    echo -e "${yellow}正在启动 Komari...${re}"

    # 确保镜像存在
    docker image inspect ${IMAGE_NAME} >/dev/null 2>&1 || docker pull ${IMAGE_NAME}

    if check_nat_available; then
        docker run -d --name ${CONTAINER_NAME} \
            -p ${PORT}:${PORT} \
            -e ADMIN_USERNAME="${ADMIN_USERNAME}" \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
            ${IMAGE_NAME}
        MODE="端口映射"
    else
        docker run -d --name ${CONTAINER_NAME} \
            --network host \
            -e ADMIN_USERNAME="${ADMIN_USERNAME}" \
            -e ADMIN_PASSWORD="${ADMIN_PASSWORD}" \
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
    docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1
}

restart_komari() {
    start_komari
}

update_komari() {
    docker pull ${IMAGE_NAME}
    restart_komari
}

uninstall_komari() {
    stop_komari
    rm -f "$CONFIG_FILE"
    echo -e "${green}✅ Komari 已卸载${re}"
}

show_logs() {
    docker logs -f ${CONTAINER_NAME}
}

change_admin() {
    read -p "请输入新的管理员账号: " ADMIN_USERNAME
    read -p "请输入新的管理员密码: " ADMIN_PASSWORD
    save_config
    echo -e "${green}管理员账号密码已修改，正在重启容器...${re}"
    restart_komari
}

change_port() {
    read -p "请输入新的端口号: " PORT
    save_config
    echo -e "${green}端口已修改，正在重启容器...${re}"
    restart_komari
}

# ================== 主程序 ==================
while true; do
    clear
    echo "===== Komari Docker 管理脚本 ====="
    echo "容器状态: $(get_status)"
    echo "当前端口: $PORT"
    echo "管理员账号: $ADMIN_USERNAME"
    echo "管理员密码: $ADMIN_PASSWORD"
    echo "================================="
    echo -e "${green}1. 启动 Komari${re}"
    echo -e "${green}2. 停止 Komari${re}"
    echo -e "${green}3. 重启 Komari${re}"
    echo -e "${green}4. 查看日志${re}"
    echo -e "${green}5. 更新 Komari${re}"
    echo -e "${green}6. 卸载 Komari${re}"
    echo -e "${green}7. 修改管理员账号密码${re}"
    echo -e "${green}8. 修改端口号${re}"
    echo -e "${green}9. 退出${re}"
    echo "================================="
    read -p "请选择操作 [1-9]: " choice

    case $choice in
        1) start_komari ;;
        2) stop_komari ;;
        3) restart_komari ;;
        4) show_logs ;;
        5) update_komari ;;
        6) uninstall_komari ;;
        7) change_admin ;;
        8) change_port ;;
        9) exit 0 ;;
        *) echo -e "${red}无效选项${re}" ;;
    esac
    read -p "按回车键返回菜单..."
done
