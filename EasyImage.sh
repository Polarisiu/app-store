#!/bin/bash

# ================= 配置 =================
docker_name="easyimage"
docker_img="ddsderek/easyimage:latest"
docker_port=85
config_dir="/home/docker/easyimage/config"
image_dir="/home/docker/easyimage/i"

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ================= 函数 =================
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker 未安装，请先安装 Docker！${RESET}"
        exit 1
    fi
}

check_port() {
    local port=$1
    while lsof -i:$port &>/dev/null; do
        echo -e "${YELLOW}端口 $port 已被占用，尝试下一个端口...${RESET}"
        port=$((port+1))
    done
    echo $port
}

install_container() {
    mkdir -p "$config_dir" "$image_dir"

    # 检测端口
    docker_port=$(check_port $docker_port)

    echo -e "${GREEN}正在拉取镜像...${RESET}"
    docker pull $docker_img

    echo -e "${GREEN}正在启动容器...${RESET}"
    docker run -d \
        --name $docker_name \
        -p $docker_port:80 \
        -e TZ=Asia/Shanghai \
        -e PUID=1000 \
        -e PGID=1000 \
        -v $config_dir:/app/web/config \
        -v $image_dir:/app/web/i \
        --restart unless-stopped \
        $docker_img

    # 获取公网 IP
    public_ip=$(curl -s ifconfig.me)
    echo -e "${GREEN}容器启动完成！${RESET}"
    echo -e "${YELLOW}访问地址: http://$public_ip:$docker_port${RESET}"
}

update_container() {
    echo -e "${GREEN}正在更新镜像...${RESET}"
    docker pull $docker_img
    docker stop $docker_name
    docker rm $docker_name

    echo -e "${GREEN}重新启动容器...${RESET}"
    install_container
}

start_container() {
    docker start $docker_name
    echo -e "${GREEN}容器已启动！${RESET}"
}

stop_container() {
    docker stop $docker_name
    echo -e "${RED}容器已停止！${RESET}"
}

restart_container() {
    docker restart $docker_name
    echo -e "${GREEN}容器已重启！${RESET}"
}

status_container() {
    docker ps -a --filter "name=$docker_name"
}

view_logs() {
    echo -e "${GREEN}显示容器日志，按 Ctrl+C 返回菜单${RESET}"
    docker logs -f $docker_name
}

uninstall_all() {
    docker stop $docker_name
    docker rm $docker_name
    echo -e "${RED}容器及所有数据已删除！${RESET}"
    rm -rf "$config_dir" "$image_dir"
}

# ================= 菜单 =================
while true; do
    echo -e "${GREEN}==============================${RESET}"
    echo -e "${GREEN} EasyImage 图床 Docker 管理菜单 ${RESET}"
    echo -e "${GREEN}==============================${RESET}"
    echo -e "${GREEN}1. 安装并启动容器${RESET}"
    echo -e "${GREEN}2. 启动容器${RESET}"
    echo -e "${GREEN}3. 停止容器${RESET}"
    echo -e "${GREEN}4. 重启容器${RESET}"
    echo -e "${GREEN}5. 查看容器状态${RESET}"
    echo -e "${GREEN}6. 更新容器镜像${RESET}"
    echo -e "${GREEN}7. 查看容器日志${RESET}"
    echo -e "${RED}8. 卸载容器并删除所有数据${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "${GREEN}==============================${RESET}"
    read -p "请选择操作 [0-8]: " choice

    case $choice in
        1) install_container ;;
        2) start_container ;;
        3) stop_container ;;
        4) restart_container ;;
        5) status_container ;;
        6) update_container ;;
        7) view_logs ;;
        8) uninstall_all ;;
        0) exit 0 ;;
        *) echo -e "${RED}输入错误，请重新选择。${RESET}" ;;
    esac
done
