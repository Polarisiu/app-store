#!/bin/bash
# ========================================
# SPlayer 一键部署 / 更新 / 卸载 脚本
# 镜像来源: imsyy/splayer
# ========================================

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

IMAGE="imsyy/splayer:latest"
CONTAINER="SPlayer"
PORT=25884

# 获取公网 IP
get_ip() {
    curl -s ipv4.icanhazip.com
}

# 检查 Docker 是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker 未安装，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
    else
        echo -e "${GREEN}Docker 已安装${RESET}"
    fi
}

# 部署
deploy() {
    check_docker
    echo -e "${GREEN}拉取 SPlayer 镜像...${RESET}"
    docker pull $IMAGE
    echo -e "${GREEN}停止并删除旧容器（如有）...${RESET}"
    docker rm -f $CONTAINER 2>/dev/null
    echo -e "${GREEN}启动 SPlayer 容器...${RESET}"
    docker run -d --name $CONTAINER -p ${PORT}:${PORT} $IMAGE
    echo -e "${GREEN}SPlayer 已启动！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(get_ip):${PORT}${RESET}"
}

# 更新
update() {
    check_docker
    echo -e "${GREEN}更新 SPlayer...${RESET}"
    docker pull $IMAGE
    docker rm -f $CONTAINER 2>/dev/null
    docker run -d --name $CONTAINER -p ${PORT}:${PORT} $IMAGE
    echo -e "${GREEN}SPlayer 已更新并重启！${RESET}"
    echo -e "访问地址: ${YELLOW}http://$(get_ip):${PORT}${RESET}"
}

# 卸载
uninstall() {
    echo -e "${RED}停止并删除容器...${RESET}"
    docker rm -f $CONTAINER 2>/dev/null
    echo -e "${RED}删除镜像...${RESET}"
    docker rmi $IMAGE 2>/dev/null
    echo -e "${GREEN}SPlayer 已卸载！${RESET}"
}

# 菜单
menu() {
    clear
    echo "====================================="
    echo "     SPlayer 一键管理脚本"
    echo "====================================="
    echo "1. 部署 SPlayer"
    echo "2. 更新 SPlayer"
    echo "3. 卸载 SPlayer"
    echo "0. 退出"
    echo "====================================="
    read -rp "请输入选项 [0-3]: " choice
    case $choice in
        1) deploy ;;
        2) update ;;
        3) uninstall ;;
        0) exit 0 ;;
        *) echo "无效选项" ;;
    esac
}

menu
