#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# ================== 默认配置 ==================
HUBP_IMAGE="ymyuuu/hubp:latest"
HUBP_CONTAINER="HubP"
DEFAULT_PORT=18826
DEFAULT_DISGUISE="onlinealarmkur.com"
DEFAULT_LOG_LEVEL="debug"

# ================== 工具函数 ==================
pause() {
    read -rp "按回车返回菜单..."
}

set_proxy() {
    read -rp "请输入 HubP 容器端口 (默认 $DEFAULT_PORT): " PORT
    PORT=${PORT:-$DEFAULT_PORT}
    export HTTP_PROXY="http://127.0.0.1:$PORT"
    export HTTPS_PROXY="http://127.0.0.1:$PORT"
    echo -e "${GREEN}✅ 已设置 HTTP_PROXY 和 HTTPS_PROXY 指向 HubP:${PORT}${RESET}"
}

remove_proxy() {
    unset HTTP_PROXY
    unset HTTPS_PROXY
    echo -e "${GREEN}✅ 已移除 HTTP_PROXY 和 HTTPS_PROXY${RESET}"
}

# ================== HubP 功能函数 ==================
deploy_hubp() {
    read -rp "请输入宿主机端口 (默认 $DEFAULT_PORT): " PORT
    PORT=${PORT:-$DEFAULT_PORT}
    read -rp "请输入 HubP DISGUISE (默认 $DEFAULT_DISGUISE): " DISGUISE
    DISGUISE=${DISGUISE:-$DEFAULT_DISGUISE}

    echo -e "${GREEN}🚀 启动 HubP 容器...${RESET}"
    docker rm -f "$HUBP_CONTAINER" >/dev/null 2>&1 || true

    docker run -d --restart unless-stopped --name "$HUBP_CONTAINER" \
        -p "$PORT:18826" \
        -e HUBP_LOG_LEVEL="$DEFAULT_LOG_LEVEL" \
        -e HUBP_DISGUISE="$DISGUISE" \
        "$HUBP_IMAGE"

    echo -e "${GREEN}✅ HubP 已启动，访问端口: $PORT, DISGUISE: $DISGUISE${RESET}"
}

update_hubp() {
    echo -e "${GREEN}🔄 拉取最新 HubP 镜像...${RESET}"
    docker pull "$HUBP_IMAGE"

    echo -e "${GREEN}♻️ 重启 HubP 容器...${RESET}"
    docker restart "$HUBP_CONTAINER"

    echo -e "${GREEN}✅ HubP 镜像已更新并重启容器成功${RESET}"
    pause
}

stop_hubp() {
    docker stop "$HUBP_CONTAINER" >/dev/null 2>&1 || true
    echo -e "${GREEN}✅ HubP 已停止${RESET}"
    pause
}

status_hubp() {
    docker ps | grep "$HUBP_CONTAINER" || echo -e "${GREEN}HubP 容器未运行${RESET}"
    pause
}

logs_hubp() {
    echo -e "${GREEN}📄 查看 HubP 日志 (按 Ctrl+C 退出)...${RESET}"
    docker logs -f "$HUBP_CONTAINER"
    pause
}

uninstall_hubp() {
    echo -e "${GREEN}🗑️ 卸载 HubP 容器及镜像...${RESET}"
    docker rm -f "$HUBP_CONTAINER" >/dev/null 2>&1 || true
    docker rmi "$HUBP_IMAGE" >/dev/null 2>&1 || true
    echo -e "${GREEN}✅ HubP 已卸载完成${RESET}"
    pause
}

# ================== 菜单 ==================
while true; do
    clear
    echo -e "${GREEN}================ HubP 管理菜单 ================${RESET}"
    echo -e "${GREEN}1. 部署/启动 HubP${RESET}"
    echo -e "${GREEN}2. 更新 HubP 镜像并重启容器${RESET}"
    echo -e "${GREEN}3. 停止 HubP${RESET}"
    echo -e "${GREEN}4. 查看状态${RESET}"
    echo -e "${GREEN}5. 查看日志${RESET}"
    echo -e "${GREEN}6. 设置 Docker 代理环境 (HTTP_PROXY/HTTPS_PROXY)${RESET}"
    echo -e "${GREEN}7. 移除 Docker 代理环境${RESET}"
    echo -e "${GREEN}8. 卸载 HubP${RESET}"
    echo -e "${GREEN}9. 退出${RESET}"
    echo -e "${GREEN}==============================================${RESET}"
    read -rp "请选择操作 [1-9]: " choice
    case $choice in
        1) deploy_hubp ;;
        2) update_hubp ;;
        3) stop_hubp ;;
        4) status_hubp ;;
        5) logs_hubp ;;
        6) set_proxy ;;
        7) remove_proxy ;;
        8) uninstall_hubp ;;
        9) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}"; pause ;;
    esac
done
