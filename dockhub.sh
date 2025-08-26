#!/bin/bash
# ================== 颜色 ==================
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# ================== 配置 ==================
CONTAINER_NAME="HubP"
IMAGE_NAME="ymyuuu/hubp:latest"

# ================== 函数 ==================
start_container() {
    read -p "请输入宿主机端口 (默认18184): " HOST_PORT
    HOST_PORT=${HOST_PORT:-18184}
    read -p "请输入 HubP DISGUISE (默认onlinealarmkur.com): " DISGUISE
    DISGUISE=${DISGUISE:-onlinealarmkur.com}

    echo -e "${GREEN}🚀 启动 HubP 容器...${RESET}"
    docker run -d --restart unless-stopped --name $CONTAINER_NAME \
      -p $HOST_PORT:$HOST_PORT \
      -e HUBP_LOG_LEVEL=debug \
      -e HUBP_DISGUISE=$DISGUISE \
      $IMAGE_NAME
    echo -e "${GREEN}✅ HubP 已启动，访问端口: $HOST_PORT, DISGUISE: $DISGUISE${RESET}"
    read -p "按回车返回菜单..."
}

stop_container() {
    if ! docker ps | grep -q $CONTAINER_NAME; then
        echo -e "${RED}❌ 容器未运行${RESET}"
    else
        echo -e "${GREEN}🛑 停止 HubP 容器...${RESET}"
        docker stop $CONTAINER_NAME
        echo -e "${GREEN}✅ HubP 已停止${RESET}"
    fi
    read -p "按回车返回菜单..."
}

uninstall_container() {
    echo -e "${GREEN}❌ 卸载 HubP 容器...${RESET}"
    docker stop $CONTAINER_NAME >/dev/null 2>&1
    docker rm $CONTAINER_NAME >/dev/null 2>&1
    echo -e "${GREEN}✅ HubP 已卸载${RESET}"
    read -p "按回车返回菜单..."
}

update_container() {
    if ! docker ps -a | grep -q $CONTAINER_NAME; then
        echo -e "${RED}❌ 容器未运行，无法更新重启${RESET}"
    else
        echo -e "${GREEN}🔄 更新 HubP 镜像...${RESET}"
        docker pull $IMAGE_NAME
        echo -e "${GREEN}✅ 镜像已更新，重启容器...${RESET}"
        docker restart $CONTAINER_NAME
        echo -e "${GREEN}✅ HubP 已重启${RESET}"
    fi
    read -p "按回车返回菜单..."
}

container_status() {
    echo -e "${GREEN}ℹ️ HubP 容器状态:${RESET}"
    docker ps -a | grep $CONTAINER_NAME || echo "容器未运行"
    read -p "按回车返回菜单..."
}

view_logs() {
    if ! docker ps | grep -q $CONTAINER_NAME; then
        echo -e "${RED}❌ 容器未运行，无法查看日志${RESET}"
    else
        echo -e "${GREEN}📄 查看 HubP 日志 (按 Ctrl+C 退出)...${RESET}"
        docker logs -f $CONTAINER_NAME
    fi
    read -p "按回车返回菜单..."
}

show_menu() {
    clear
    echo -e "${GREEN}================ HubP 管理菜单 ================${RESET}"
    echo -e "${GREEN}1. 部署/启动 HubP (可自定义端口和DISGUISE)${RESET}"
    echo -e "${GREEN}2. 停止 HubP${RESET}"
    echo -e "${GREEN}3. 更新 HubP 镜像并重启容器${RESET}"
    echo -e "${GREEN}4. 查看状态${RESET}"
    echo -e "${GREEN}5. 卸载 HubP${RESET}"
    echo -e "${GREEN}6. 查看日志${RESET}"
    echo -e "${GREEN}7. 退出${RESET}"
    echo -e "${GREEN}==============================================${RESET}"
    read -p "请选择操作 [1-7]: " choice
    case $choice in
        1) start_container ;;
        2) stop_container ;;
        3) update_container ;;
        4) container_status ;;
        5) uninstall_container ;;
        6) view_logs ;;
        7) exit 0 ;;
        *) echo -e "${RED}❌ 无效选项${RESET}" ; read -p "按回车返回菜单..." ;;
    esac
    show_menu
}

# ================== 主程序 ==================
show_menu
