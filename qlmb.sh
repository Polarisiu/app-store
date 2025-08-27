#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ================== 检查 Docker ==================
check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}检测到 Docker 未安装，正在安装...${RESET}"
        curl -sSL https://get.docker.com | sh
    fi
}

# ================== 获取公网 IP ==================
get_public_ip() {
    PUBLIC_IP=$(curl -s https://ifconfig.me)
    if [[ -z "$PUBLIC_IP" ]]; then
        echo -e "${RED}无法获取公网 IP，请检查网络设置。${RESET}"
        exit 1
    fi
    echo "$PUBLIC_IP"
}

# ================== 部署 QingLong ==================
deploy_qinglong() {
    read -rp "请输入 QingLong 部署端口 (默认 5700): " QL_PORT
    QL_PORT=${QL_PORT:-5700}

    mkdir -p "$PWD/ql/data"

    echo -e "${GREEN}拉取 QingLong 镜像...${RESET}"
    docker pull whyour/qinglong:latest

    if docker ps -a --format '{{.Names}}' | grep -q '^qinglong$'; then
        echo -e "${YELLOW}发现已存在的 QingLong 容器，正在停止并删除...${RESET}"
        docker stop qinglong
        docker rm qinglong
    fi

    docker run -dit \
        -v "$PWD/ql/data:/ql/data" \
        -p "${QL_PORT}:${QL_PORT}" \
        -e QlBaseUrl="/" \
        -e QlPort="${QL_PORT}" \
        --name qinglong \
        --hostname qinglong \
        --restart unless-stopped \
        whyour/qinglong:latest

    PUBLIC_IP=$(get_public_ip)
    echo -e "${GREEN}QingLong 已成功启动，访问地址: http://${PUBLIC_IP}:${QL_PORT}${RESET}"
}

# ================== 管理 QingLong ==================
manage_qinglong() {
    while true; do
        echo -e "${GREEN}=== QingLong 管理菜单 ===${RESET}"
        echo -e "${GREEN}1. 查看容器状态${RESET}"
        echo -e "${GREEN}2. 启动容器${RESET}"
        echo -e "${GREEN}3. 停止容器${RESET}"
        echo -e "${GREEN}4. 重启容器${RESET}"
        echo -e "${GREEN}5. 查看日志${RESET}"
        echo -e "${GREEN}6. 删除容器${RESET}"
        echo -e "${GREEN}7. 更新镜像并重启${RESET}"
        echo -e "${GREEN}0. 退出${RESET}"

        read -rp "请选择操作: " choice
        case "$choice" in
            1)
                docker ps -a | grep qinglong || echo -e "${GREEN}未找到 QingLong 容器${RESET}"
                ;;
            2)
                docker start qinglong
                ;;
            3)
                docker stop qinglong
                ;;
            4)
                docker restart qinglong
                ;;
            5)
                docker logs -f qinglong
                ;;
            6)
                read -rp "确定要删除 QingLong 容器吗? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    docker stop qinglong
                    docker rm qinglong
                fi
                ;;
            7)
                echo -e "${GREEN}拉取最新 QingLong 镜像...${RESET}"
                docker pull whyour/qinglong:latest

                if docker ps --format '{{.Names}}' | grep -q '^qinglong$'; then
                    echo -e "${GREEN}停止容器...${RESET}"
                    docker stop qinglong
                    echo -e "${GREEN}使用新镜像重启容器...${RESET}"
                    docker start qinglong
                else
                    echo -e "${RED}未找到正在运行的 QingLong 容器，请先部署${RESET}"
                fi

                PUBLIC_IP=$(get_public_ip)
                CONTAINER_PORT=$(docker port qinglong | awk -F':' '{print $2}')
                echo -e "${GREEN}更新完成，访问地址: http://${PUBLIC_IP}:${CONTAINER_PORT}${RESET}"
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}无效选项${RESET}"
                ;;
        esac
        echo
    done
}

# ================== 执行 ==================
check_docker
deploy_qinglong
manage_qinglong
