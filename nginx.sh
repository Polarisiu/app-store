#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# 容器配置
DOCKER_NAME="npm"
DOCKER_IMG="jc21/nginx-proxy-manager:latest"
DOCKER_PORT=81
DATA_PATH="/home/docker/npm/data"
CERT_PATH="/home/docker/npm/letsencrypt"

# 获取公网 IP
get_public_ip() {
    local ip=""
    ip=$(curl -s ipv4.ip.sb)
    [[ -z "$ip" ]] && ip=$(curl -s ifconfig.me)
    [[ -z "$ip" ]] && ip=$(curl -s ipinfo.io/ip)
    if [[ -z "$ip" ]]; then
        echo -e "${GREEN}无法获取公网 IP${RESET}"
        return 1
    fi
    echo "$ip"
}

# 自动更新镜像
docker_update_image() {
    echo -e "${GREEN}正在拉取最新 NPM 镜像...${RESET}"
    docker pull $DOCKER_IMG
}

# 启动容器函数（部署 + 更新）
docker_run() {
    # 检测端口是否被占用
    if lsof -i:80 -sTCP:LISTEN || lsof -i:443 -sTCP:LISTEN; then
        echo -e "${RED}⚠️  80/443 端口已被占用，请先释放端口再运行 NPM${RESET}"
        return 1
    fi

    mkdir -p $DATA_PATH $CERT_PATH

    # 自动拉取最新镜像
    docker_update_image

    # 如果容器存在，先删除
    if docker ps -a --format '{{.Names}}' | grep -q "^${DOCKER_NAME}$"; then
        echo -e "${GREEN}检测到已有 NPM 容器，正在删除旧容器...${RESET}"
        docker rm -f $DOCKER_NAME
    fi

    docker run -d \
      --name=$DOCKER_NAME \
      -p ${DOCKER_PORT}:81 \
      -p 80:80 \
      -p 443:443 \
      -v $DATA_PATH:/data \
      -v $CERT_PATH:/etc/letsencrypt \
      --restart=always \
      $DOCKER_IMG

    PUBLIC_IP=$(get_public_ip)

    echo -e "${GREEN}✅ Nginx Proxy Manager 已安装并启动${RESET}"
    echo -e "${GREEN}管理面板地址: http://${PUBLIC_IP}:${DOCKER_PORT}${RESET}"
    echo -e "${GREEN}初始用户名: admin@example.com${RESET}"
    echo -e "${GREEN}初始密码: changeme${RESET}"
}

# 卸载容器
docker_remove() {
    docker rm -f $DOCKER_NAME 2>/dev/null
    echo -e "${GREEN}✅ NPM 已卸载${RESET}"
}

# 查看日志
docker_logs() {
    docker logs -f $DOCKER_NAME
}

# 菜单函数
menu() {
    clear
    echo -e "${GREEN}=== Nginx Proxy Manager 一键管理菜单 ===${RESET}"
    echo -e "${GREEN}1. 部署 / 更新 NPM${RESET}"
    echo -e "${GREEN}2. 启动 NPM${RESET}"
    echo -e "${GREEN}3. 停止 NPM${RESET}"
    echo -e "${GREEN}4. 重启 NPM${RESET}"
    echo -e "${GREEN}5. 查看日志${RESET}"
    echo -e "${GREEN}6. 卸载 NPM${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "${GREEN}=========================================${RESET}"
    read -p $'\033[32m请输入选项: \033[0m' choice

    case $choice in
        1) docker_run ;;
        2) echo -e "${GREEN}启动 NPM...${RESET}" ; docker start $DOCKER_NAME ;;
        3) echo -e "${GREEN}停止 NPM...${RESET}" ; docker stop $DOCKER_NAME ;;
        4) echo -e "${GREEN}重启 NPM...${RESET}" ; docker restart $DOCKER_NAME ;;
        5) echo -e "${GREEN}查看日志...${RESET}" ; docker_logs ;;
        6) echo -e "${GREEN}卸载 NPM...${RESET}" ; docker_remove ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
}

# 循环显示菜单
while true; do
    menu
    read -p $'\033[32m按回车返回菜单...\033[0m' foo
done
