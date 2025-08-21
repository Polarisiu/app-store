#!/bin/bash
# ========================================
# Wallos Docker 管理脚本（菜单版 + 彩色输出）
# ========================================

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

APP_NAME="wallos"
APP_PORT=9800
DATA_DIR="/root/wallos/data"
LOGO_DIR="/root/wallos/logos"
TIMEZONE="Asia/Shanghai"
IMAGE_NAME="bellamy/wallos:latest"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装，请先安装 Docker 再运行此脚本。${RESET}"
    exit 1
fi

# 安装 / 更新函数
install_or_update_wallos() {
    mkdir -p "$DATA_DIR" "$LOGO_DIR"

    # 删除旧容器
    if docker ps -a --format '{{.Names}}' | grep -w "$APP_NAME" &> /dev/null; then
        echo -e "${YELLOW}⚠️ 检测到已有容器 [$APP_NAME]，正在删除...${RESET}"
        docker stop "$APP_NAME" &> /dev/null
        docker rm "$APP_NAME" &> /dev/null
    fi

    # 拉取最新镜像
    echo -e "${CYAN}⬇️ 拉取最新镜像...${RESET}"
    docker pull "$IMAGE_NAME"

    # 启动容器
    echo -e "${CYAN}🚀 正在部署 Wallos...${RESET}"
    docker run -d \
        --restart unless-stopped \
        --name "$APP_NAME" \
        -p ${APP_PORT}:80 \
        -v "$DATA_DIR":/var/www/html/db \
        -v "$LOGO_DIR":/var/www/html/images/uploads/logos \
        -e TZ="$TIMEZONE" \
        "$IMAGE_NAME"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Wallos 部署完成！${RESET}"
        echo -e "${GREEN}访问地址：http://$(curl -s ifconfig.me):${APP_PORT}${RESET}"
    else
        echo -e "${RED}❌ 部署失败，请检查 Docker 配置。${RESET}"
    fi
}

# 卸载函数
uninstall_wallos() {
    if docker ps -a --format '{{.Names}}' | grep -w "$APP_NAME" &> /dev/null; then
        echo -e "${YELLOW}⚠️ 停止并删除容器 [$APP_NAME]...${RESET}"
        docker stop "$APP_NAME" &> /dev/null
        docker rm "$APP_NAME" &> /dev/null
        echo -e "${GREEN}✅ 容器已删除${RESET}"
    else
        echo -e "${YELLOW}⚠️ 未检测到容器 [$APP_NAME]${RESET}"
    fi

    read -p "是否删除数据目录和 Logo 目录？(y/N): " DELETE_DIR
    if [[ "$DELETE_DIR" =~ ^[Yy]$ ]]; then
        rm -rf "$DATA_DIR" "$LOGO_DIR"
        echo -e "${GREEN}✅ 数据目录已删除${RESET}"
    fi
}

# 查看容器状态
check_status() {
    if docker ps -a | grep "$APP_NAME" &> /dev/null; then
        docker ps -a | grep "$APP_NAME"
    else
        echo -e "${YELLOW}⚠️ 未检测到容器 [$APP_NAME]${RESET}"
    fi
}

# 菜单主循环
while true; do
    echo -e "${BLUE}==============================${RESET}"
    echo -e "${CYAN}Wallos Docker 管理菜单${RESET}"
    echo -e "${BLUE}==============================${RESET}"
    echo -e "${YELLOW}1) 安装 Wallos${RESET}"
    echo -e "${YELLOW}2) 更新 Wallos${RESET}"
    echo -e "${YELLOW}3) 卸载 Wallos${RESET}"
    echo -e "${YELLOW}4) 查看容器状态${RESET}"
    echo -e "${YELLOW}5) 退出${RESET}"
    echo -e "${BLUE}==============================${RESET}"
    read -p "请选择操作 [1-5]: " CHOICE

    case $CHOICE in
        1) install_or_update_wallos ;;
        2) install_or_update_wallos ;;
        3) uninstall_wallos ;;
        4) check_status ;;
        5) echo -e "${CYAN}退出脚本${RESET}"; exit 0 ;;
        *) echo -e "${RED}❌ 无效选择，请输入 1-5${RESET}" ;;
    esac
done
