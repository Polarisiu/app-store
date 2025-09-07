#!/bin/bash
# ========================================
# MoviePilot V2 Docker 管理脚本
# ========================================

# 颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

CONTAINER_NAME="moviepilot-v2"
CONFIG_DIR="/moviepilot-v2/config"
CACHE_DIR="/moviepilot-v2/core"
MEDIA_DIR="/media"
IMAGE_NAME="jxxghp/moviepilot-v2:latest"

# 部署并运行容器
deploy_moviepilot() {
    echo -e "${YELLOW}创建目录...${RESET}"
    mkdir -p "${CONFIG_DIR}" "${CACHE_DIR}" "${MEDIA_DIR}"

    echo -e "${YELLOW}启动 MoviePilot V2 Docker 容器...${RESET}"
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --hostname "${CONTAINER_NAME}" \
        --network host \
        -v "${MEDIA_DIR}":/media \
        -v "${CONFIG_DIR}":/config \
        -v "${CACHE_DIR}":/moviepilot/.cache/ms-playwright \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -e NGINX_PORT=3000 \
        -e PORT=3001 \
        -e PUID=0 \
        -e PGID=0 \
        -e UMASK=000 \
        -e TZ=Asia/Shanghai \
        -e SUPERUSER=admin \
        --restart always \
        ${IMAGE_NAME}

    echo -e "${GREEN}MoviePilot V2 Docker 容器已部署并启动！${RESET}"
    echo -e "${CYAN}WebUI 默认访问端口: 3000 (NGINX) / 3001 (应用端口)${RESET}"
}

# 启动容器
start_moviepilot() {
    docker start "${CONTAINER_NAME}" && echo -e "${GREEN}MoviePilot V2 已启动${RESET}"
}

# 停止容器
stop_moviepilot() {
    docker stop "${CONTAINER_NAME}" && echo -e "${YELLOW}MoviePilot V2 已停止${RESET}"
}

# 重启容器
restart_moviepilot() {
    docker restart "${CONTAINER_NAME}" && echo -e "${GREEN}MoviePilot V2 已重启${RESET}"
}

# 查看日志
logs_moviepilot() {
    docker logs -f "${CONTAINER_NAME}"
}

# 卸载容器
uninstall_moviepilot() {
    docker rm -f "${CONTAINER_NAME}"
    echo -e "${YELLOW}是否删除配置和缓存目录？[y/N]${RESET}"
    read -r del
    if [[ "$del" == "y" || "$del" == "Y" ]]; then
        rm -rf "${CONFIG_DIR}" "${CACHE_DIR}"
        echo -e "${RED}配置和缓存已删除${RESET}"
    fi
    echo -e "${GREEN}MoviePilot V2 已卸载${RESET}"
}
# 更新容器
update_moviepilot() {
    echo -e "${YELLOW}正在更新 MoviePilot V2...${RESET}"
    docker pull "${IMAGE_NAME}"

    echo -e "${YELLOW}停止并删除旧容器...${RESET}"
    docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true

    echo -e "${YELLOW}重新部署容器...${RESET}"
    docker run -d \
        --name "${CONTAINER_NAME}" \
        --hostname "${CONTAINER_NAME}" \
        --network host \
        -v "${MEDIA_DIR}":/media \
        -v "${CONFIG_DIR}":/config \
        -v "${CACHE_DIR}":/moviepilot/.cache/ms-playwright \
        -v /var/run/docker.sock:/var/run/docker.sock:ro \
        -e NGINX_PORT=3000 \
        -e PORT=3001 \
        -e PUID=0 \
        -e PGID=0 \
        -e UMASK=000 \
        -e TZ=Asia/Shanghai \
        -e SUPERUSER=admin \
        --restart always \
        ${IMAGE_NAME}

    echo -e "${GREEN}MoviePilot V2 已更新并重新启动！${RESET}"
}

# 菜单
menu() {
    clear
    echo -e "${GREEN}==== MoviePilot V2 Docker 管理菜单 ====${RESET}"
    echo -e "${GREEN}1. 一键部署 & 启动容器${RESET}"
    echo -e "${GREEN}2. 启动容器${RESET}"
    echo -e "${GREEN}3. 停止容器${RESET}"
    echo -e "${GREEN}4. 重启容器${RESET}"
    echo -e "${GREEN}5. 查看日志${RESET}"
    echo -e "${GREEN}6. 更新容器${RESET}"
    echo -e "${GREEN}7. 卸载容器${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -ne "${YELLOW}请输入选项: ${RESET}"
    read -r choice
    case "$choice" in
        1) deploy_moviepilot ;;
        2) start_moviepilot ;;
        3) stop_moviepilot ;;
        4) restart_moviepilot ;;
        5) logs_moviepilot ;;
        6) update_moviepilot ;;
        7) uninstall_moviepilot ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
}

# 循环菜单
while true; do
    menu
    echo -e "${YELLOW}按回车键继续...${RESET}"
    read -r
done
