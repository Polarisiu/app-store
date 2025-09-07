#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

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
    if ! command -v docker &>/dev/null; then
        echo -e "${RED}未检测到 Docker，请先安装 Docker${RESET}"
        return
    fi

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
update_qinglong() {
    echo -e "${GREEN}>>> 拉取最新 QingLong 镜像...${RESET}"
    docker pull whyour/qinglong:latest

    if docker ps -a --format '{{.Names}}' | grep -q '^qinglong$'; then
        echo -e "${GREEN}>>> 删除旧容器...${RESET}"
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
    echo -e "${GREEN}✅ QingLong 已更新并启动完成，访问地址: http://${PUBLIC_IP}:${QL_PORT}${RESET}"
}

# ================== 管理 QingLong ==================
manage_qinglong() {
    while true; do
        echo -e "${GREEN}=== QingLong 管理菜单 ===${RESET}"
        echo -e "${GREEN}1. 部署 QingLong${RESET}"
        echo -e "${GREEN}2. 查看容器状态${RESET}"
        echo -e "${GREEN}3. 启动容器${RESET}"
        echo -e "${GREEN}4. 停止容器${RESET}"
        echo -e "${GREEN}5. 重启容器${RESET}"
        echo -e "${GREEN}6. 查看日志${RESET}"
        echo -e "${GREEN}7. 删除容器${RESET}"
        echo -e "${GREEN}8. 更新镜像并重启${RESET}"
        echo -e "${GREEN}0. 退出${RESET}"

        read -rp "请选择操作: " choice
        case "$choice" in
            1)
                deploy_qinglong
                ;;
            2)
                docker ps -a | grep qinglong || echo -e "${GREEN}未找到 QingLong 容器${RESET}"
                ;;
            3)
                docker start qinglong
                ;;
            4)
                docker stop qinglong
                ;;
            5)
                docker restart qinglong
                ;;
            6)
                docker logs -f qinglong
                ;;
            7)
                read -rp "确定要删除 QingLong 容器吗? (y/n): " confirm
                if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                    docker stop qinglong
                    docker rm qinglong
                fi
                ;;
            8)
                read -rp "请输入容器端口 (默认 $QL_PORT): " QL_PORT
                QL_PORT=${QL_PORT:-5700}
                update_qinglong  
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
manage_qinglong
