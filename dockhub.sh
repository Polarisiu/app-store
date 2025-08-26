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

docker_insecure_registry() {
    DAEMON_FILE="/etc/docker/daemon.json"
    if [ -f "$DAEMON_FILE" ]; then
        jq ".insecure-registries += [\"127.0.0.1:$1\"]" "$DAEMON_FILE" > "$DAEMON_FILE".tmp 2>/dev/null || true
        mv "$DAEMON_FILE".tmp "$DAEMON_FILE"
    else
        echo "{\"insecure-registries\": [\"127.0.0.1:$1\"]}" > "$DAEMON_FILE"
    fi
    sudo systemctl restart docker
}

deploy_hubp() {
    read -rp "请输入宿主机端口 (默认 $DEFAULT_PORT): " PORT
    PORT=${PORT:-$DEFAULT_PORT}
    read -rp "请输入 HubP DISGUISE (默认 $DEFAULT_DISGUISE): " DISGUISE
    DISGUISE=${DISGUISE:-$DEFAULT_DISGUISE}

    echo -e "${GREEN}🚀 启动 HubP 容器...${RESET}"
    docker rm -f "$HUBP_CONTAINER" >/dev/null 2>&1 || true

    sudo docker run -d --restart unless-stopped --name "$HUBP_CONTAINER" \
        -p "$PORT:18826" \
        -e HUBP_LOG_LEVEL="$DEFAULT_LOG_LEVEL" \
        -e HUBP_DISGUISE="$DISGUISE" \
        "$HUBP_IMAGE"

    echo -e "${GREEN}✅ HubP 已启动，访问端口: $PORT, DISGUISE: $DISGUISE${RESET}"

    echo -e "${GREEN}⚙️ 配置 Docker 允许 HTTP 不安全仓库...${RESET}"
    docker_insecure_registry "$PORT"

    echo -e "${GREEN}🔄 测试拉取 hello-world 镜像...${RESET}"
    docker pull 127.0.0.1:"$PORT"/library/hello-world:latest && echo -e "${GREEN}✅ 镜像拉取成功${RESET}"
    pause
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
    docker rm -f "$HUBP_CONTAINER" >/dev/null 2>&1 || true
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

# ================== 菜单 ==================
while true; do
    clear
    echo -e "${GREEN}================ HubP 管理菜单 ================${RESET}"
    echo -e "${GREEN}1. 部署/启动 HubP${RESET}"
    echo -e "${GREEN}2. 更新 HubP 镜像并重启容器${RESET}"
    echo -e "${GREEN}3. 停止 HubP${RESET}"
    echo -e "${GREEN}4. 查看状态${RESET}"
    echo -e "${GREEN}5. 查看日志${RESET}"
    echo -e "${GREEN}6. 退出${RESET}"
    echo -e "${GREEN}==============================================${RESET}"
    read -rp "请选择操作 [1-6]: " choice
    case $choice in
        1) deploy_hubp ;;
        2) update_hubp ;;
        3) stop_hubp ;;
        4) status_hubp ;;
        5) logs_hubp ;;
        6) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}"; pause ;;
    esac
done
