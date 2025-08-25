#!/bin/bash
# ========================================
# 🐳 一键 VPS Docker 管理工具（完整整合版）
# ========================================

# -----------------------------
# 颜色
# -----------------------------
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

# -----------------------------
# 检查 root
# -----------------------------
root_use() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用 root 用户运行脚本${RESET}"
        exit 1
    fi
}

# -----------------------------
# 检测 Docker 是否运行
# -----------------------------
check_docker_running() {
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}Docker 未安装${RESET}"
        return 1
    fi
    if ! docker info &>/dev/null; then
        echo -e "${YELLOW}Docker 未运行，尝试启动...${RESET}"
        if systemctl list-unit-files | grep -q "^docker.service"; then
            systemctl start docker
        else
            nohup dockerd >/dev/null 2>&1 &
            sleep 5
        fi
    fi
    if ! docker info &>/dev/null; then
        echo -e "${RED}Docker 启动失败，请检查日志${RESET}"
        return 1
    fi
    echo -e "${GREEN}Docker 已启动${RESET}"
    return 0
}

# -----------------------------
# 自动检测国内/国外
# -----------------------------
detect_country() {
    local country=$(curl -s --max-time 5 ipinfo.io/country)
    if [[ "$country" == "CN" ]]; then
        echo "CN"
    else
        echo "OTHER"
    fi
}

# -----------------------------
# 安装/更新 Docker
# -----------------------------
docker_install() {
    root_use
    local country=$(detect_country)
    echo -e "${CYAN}检测到国家: $country${RESET}"
    if [ "$country" = "CN" ]; then
        echo -e "${YELLOW}使用国内源安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://docker.0.unsee.tech",
    "https://docker.1panel.live",
    "https://registry.dockermirror.com",
    "https://docker.m.daocloud.io"
  ]
}
EOF
    else
        echo -e "${YELLOW}使用官方源安装 Docker...${RESET}"
        curl -fsSL https://get.docker.com | sh
    fi
    systemctl enable docker
    systemctl start docker
    echo -e "${GREEN}Docker 安装完成并已启动（已设置开机自启）${RESET}"
}

docker_update() {
    root_use
    echo -e "${YELLOW}正在更新 Docker...${RESET}"
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl enable docker
    systemctl restart docker
    echo -e "${GREEN}Docker 更新完成并已启动（已设置开机自启）${RESET}"
}

docker_install_update() {
    root_use
    if command -v docker &>/dev/null; then
        docker_update
    else
        docker_install
    fi
}

# -----------------------------
# 卸载 Docker（彻底）
# -----------------------------
docker_uninstall() {
    root_use
    echo -e "${RED}正在卸载 Docker...${RESET}"

    # 停止服务
    systemctl stop docker 2>/dev/null
    systemctl disable docker 2>/dev/null
    pkill dockerd 2>/dev/null

    # 卸载各种包
    if command -v apt &>/dev/null; then
        apt remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io || true
        apt purge -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io || true
        apt autoremove -y
    elif command -v yum &>/dev/null; then
        yum remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io || true
    fi

    # 删除 Docker 文件
    rm -rf /var/lib/docker /etc/docker /var/lib/containerd /var/run/docker.sock

    echo -e "${GREEN}Docker 已卸载干净${RESET}"
}

# -----------------------------
# Docker Compose 安装/更新
# -----------------------------
docker_compose_install_update() {
    root_use
    echo -e "${CYAN}正在安装/更新 Docker Compose...${RESET}"
    if ! command -v jq &>/dev/null; then
        if command -v apt &>/dev/null; then
            apt update -y && apt install -y jq
        elif command -v yum &>/dev/null; then
            yum install -y jq
        fi
    fi
    local latest=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
    latest=${latest:-"v2.30.0"}
    curl -L "https://github.com/docker/compose/releases/download/$latest/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}Docker Compose 已安装/更新到版本 $latest${RESET}"
}

# -----------------------------
# Docker IPv6
# -----------------------------
docker_ipv6_on() {
    root_use
    mkdir -p /etc/docker
    if [ -f /etc/docker/daemon.json ]; then
        jq '. + {ipv6:true,"fixed-cidr-v6":"2001:db8:1::/64"}' /etc/docker/daemon.json 2>/dev/null \
            >/etc/docker/daemon.json.tmp || echo '{"ipv6":true,"fixed-cidr-v6":"2001:db8:1::/64"}' > /etc/docker/daemon.json.tmp
    else
        echo '{"ipv6":true,"fixed-cidr-v6":"2001:db8:1::/64"}' > /etc/docker/daemon.json.tmp
    fi
    mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
    systemctl restart docker 2>/dev/null || nohup dockerd >/dev/null 2>&1 &
    echo -e "${GREEN}Docker IPv6 已开启${RESET}"
}

docker_ipv6_off() {
    root_use
    if [ -f /etc/docker/daemon.json ]; then
        jq 'del(.ipv6) | del(.["fixed-cidr-v6"])' /etc/docker/daemon.json > /etc/docker/daemon.json.tmp
        mv /etc/docker/daemon.json.tmp /etc/docker/daemon.json
        systemctl restart docker 2>/dev/null || nohup dockerd >/dev/null 2>&1 &
        echo -e "${GREEN}Docker IPv6 已关闭${RESET}"
    else
        echo -e "${YELLOW}Docker 配置文件不存在${RESET}"
    fi
}

# -----------------------------
# 开放所有端口
# -----------------------------
open_all_ports() {
    root_use
    read -p "⚠️ 确认要开放所有端口吗？(Y/N): " confirm
    [[ $confirm =~ [Yy] ]] || return
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
    echo -e "${GREEN}已开放所有端口${RESET}"
}

# -----------------------------
# 容器管理
# -----------------------------
docker_ps() {
    if ! check_docker_running; then return; fi
    while true; do
        clear
        echo -e "${BOLD}${CYAN}===== Docker 容器管理 =====${RESET}"
        docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo -e "${GREEN}01. 创建新容器${RESET}"
        echo -e "${GREEN}02. 启动容器${RESET}"
        echo -e "${GREEN}03. 停止容器${RESET}"
        echo -e "${GREEN}04. 删除容器${RESET}"
        echo -e "${GREEN}05. 重启容器${RESET}"
        echo -e "${GREEN}06. 启动所有容器${RESET}"
        echo -e "${GREEN}07. 停止所有容器${RESET}"
        echo -e "${GREEN}08. 删除所有容器${RESET}"
        echo -e "${GREEN}09. 重启所有容器${RESET}"
        echo -e "${GREEN}11. 进入容器${RESET}"
        echo -e "${GREEN}12. 查看日志${RESET}"
        echo -e "${GREEN}13. 查看网络信息${RESET}"
        echo -e "${GREEN}14. 查看占用资源${RESET}"
        echo -e "${GREEN}0.  返回主菜单${RESET}"
        read -p "请选择: " choice
        case $choice in
            01|1) read -p "请输入创建命令: " cmd; $cmd ;;
            02|2) read -p "请输入容器名: " name; docker start $name ;;
            03|3) read -p "请输入容器名: " name; docker stop $name ;;
            04|4) read -p "请输入容器名: " name; docker rm -f $name ;;
            05|5) read -p "请输入容器名: " name; docker restart $name ;;
            06|6) containers=$(docker ps -a -q); [ -n "$containers" ] && docker start $containers || echo "无容器可启动" ;;
            07|7) containers=$(docker ps -q); [ -n "$containers" ] && docker stop $containers || echo "无容器正在运行" ;;
            08|8) read -p "确定删除所有容器? (Y/N): " c; [[ $c =~ [Yy] ]] && docker rm -f $(docker ps -a -q) ;;
            09|9) containers=$(docker ps -q); [ -n "$containers" ] && docker restart $containers || echo "无容器正在运行" ;;
            11) read -p "请输入容器名: " name; docker exec -it $name sh || docker exec -it $name bash ;;
            12) read -p "请输入容器名: " name; docker logs $name ;;
            13) docker ps -q | while read cid; do docker inspect --format '{{.Name}} {{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{$v.IPAddress}}{{end}}' $cid; done ;;
            14) docker stats --no-stream ;;
            0) break ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

# -----------------------------
# 镜像管理
# -----------------------------
docker_image() {
    if ! check_docker_running; then return; fi
    while true; do
        clear
        echo -e "${BOLD}${CYAN}===== Docker 镜像管理 =====${RESET}"
        docker image ls
        echo -e "${GREEN}01. 拉取镜像${RESET}"
        echo -e "${GREEN}02. 更新镜像${RESET}"
        echo -e "${GREEN}03. 删除镜像${RESET}"
        echo -e "${GREEN}04. 删除所有镜像${RESET}"
        echo -e "${GREEN}0.  返回主菜单${RESET}"
        read -p "请选择: " choice
        case $choice in
            01|1) read -p "请输入镜像名: " imgs; for img in $imgs; do docker pull $img; done ;;
            02|2) read -p "请输入镜像名: " imgs; for img in $imgs; do docker pull $img; done ;;
            03|3) read -p "请输入镜像名: " imgs; for img in $imgs; do docker rmi -f $img; done ;;
            04|4) read -p "确定删除所有镜像? (Y/N): " c; [[ $c =~ [Yy] ]] && docker rmi -f $(docker images -q) ;;
            0) break ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

# -----------------------------
# 网络管理
# -----------------------------
docker_network() {
    if ! check_docker_running; then return; fi
    while true; do
        clear
        echo -e "${BOLD}${CYAN}===== Docker 网络管理 =====${RESET}"
        docker network ls
        echo -e "${GREEN}1. 创建网络${RESET}"
        echo -e "${GREEN}2. 加入网络${RESET}"
        echo -e "${GREEN}3. 退出网络${RESET}"
        echo -e "${GREEN}4. 删除网络${RESET}"
        echo -e "${GREEN}0. 返回上一级菜单${RESET}"
        read -p "请输入你的选择: " sub_choice
        case $sub_choice in
            1) read -p "设置新网络名: " dockernetwork; docker network create $dockernetwork ;;
            2) read -p "加入网络名: " dockernetwork; read -p "容器名: " dockername; docker network connect $dockernetwork $dockername ;;
            3) read -p "退出网络名: " dockernetwork; read -p "容器名: " dockername; docker network disconnect $dockernetwork $dockername ;;
            4) read -p "请输入要删除的网络名: " dockernetwork; docker network rm $dockernetwork ;;
            0) break ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

# -----------------------------
# 主菜单
# -----------------------------
main_menu() {
    root_use
    while true; do
        clear
        echo -e "\033[36m"
        echo "  ____             _             "
        echo " |  _ \  ___   ___| | _____ _ __ "
        echo " | | | |/ _ \ / __| |/ / _ \ '__|"
        echo " | |_| | (_) | (__|   <  __/ |   "
        echo " |____/ \___/ \___|_|\_\___|_|   "
        echo -e "\033[33m🐳 一键 VPS Docker 管理工具${RESET}"
        echo -e "${GREEN}01. 安装/更新 Docker（自动检测国内/国外源）${RESET}"
        echo -e "${GREEN}02. 安装/更新 Docker Compose${RESET}"
        echo -e "${GREEN}03. 卸载 Docker${RESET}"
        echo -e "${GREEN}04. 容器管理${RESET}"
        echo -e "${GREEN}05. 镜像管理${RESET}"
        echo -e "${GREEN}06. 开启 IPv6${RESET}"
        echo -e "${GREEN}07. 关闭 IPv6${RESET}"
        echo -e "${GREEN}08. 开放所有端口${RESET}"
        echo -e "${GREEN}09. 网络管理${RESET}"
        echo -e "${GREEN}0. 退出${RESET}"

        read -p "请选择: " choice
        case $choice in
            01|1) docker_install_update ;;
            02|2) docker_compose_install_update ;;
            03|3) docker_uninstall ;;
            04|4) docker_ps ;;
            05|5) docker_image ;;
            06|6) docker_ipv6_on ;;
            07|7) docker_ipv6_off ;;
            08|8) open_all_ports ;;
            09|9) docker_network ;;
            0) exit 0 ;;
            *) echo "无效选择" ;;
        esac
        read -p "按回车继续..."
    done
}

# 启动脚本
main_menu
