#!/bin/sh
set -e

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

info() { echo -e "${GREEN}[INFO] $1${RESET}"; }
warn() { echo -e "${YELLOW}[WARN] $1${RESET}"; }
error() { echo -e "${RED}[ERROR] $1${RESET}"; }

install_docker() {
    info "更新 apk 源..."
    apk update
    apk upgrade

    info "安装 Docker..."
    apk add docker

    info "安装依赖..."
    apk add py3-pip curl

    info "安装 Docker Compose V2..."
    COMPOSE_LATEST=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -L "https://github.com/docker/compose/releases/download/v$COMPOSE_LATEST/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    info "设置 Docker 开机自启..."
    rc-update add docker boot

    info "清理旧 socket 和日志..."
    rm -f /var/run/docker.sock /var/log/docker.log

    info "启动 Docker 服务..."
    service docker start

    info "验证安装..."
    docker version
    docker-compose version

    if docker info >/dev/null 2>&1; then
        info "Docker 安装并可用"
    else
        warn "Docker daemon 尚未就绪，请稍等再试"
    fi
    pause
}

update_docker() {
    info "更新 apk 源..."
    apk update
    apk upgrade

    info "更新 Docker..."
    apk add --upgrade docker

    info "更新 Docker Compose V2..."
    COMPOSE_LATEST=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
    curl -L "https://github.com/docker/compose/releases/download/v$COMPOSE_LATEST/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    info "重启 Docker 服务..."
    service docker restart

    info "更新完成"
    docker version
    docker-compose version
    pause
}

uninstall_docker() {
    info "停止 Docker 服务..."
    service docker stop || true

    info "卸载 Docker 和 Docker Compose..."
    apk del docker py3-pip
    rm -f /usr/local/bin/docker-compose

    info "移除开机自启..."
    rc-update del docker

    info "卸载完成"
    pause
}

check_status() {
    if service docker status >/dev/null 2>&1; then
        info "Docker 服务正在运行"
    else
        warn "Docker 服务未运行"
    fi
    pause
}

restart_docker() {
    info "重启 Docker 服务..."
    service docker restart
    check_status
    pause
}

pause() {
    echo
    read -p "按回车键返回菜单..." dummy
}

show_menu() {
    clear
    echo -e "${GREEN}==============================${RESET}"
    echo -e "${GREEN}  Alpine Docker 管理脚本${RESET}"
    echo -e "${GREEN}==============================${RESET}"
    echo -e "${GREEN}1) 安装 Docker + Docker Compose${RESET}"
    echo -e "${GREEN}2) 更新 Docker + Docker Compose${RESET}"
    echo -e "${GREEN}3) 卸载 Docker + Docker Compose${RESET}"
    echo -e "${GREEN}4) 查看 Docker 服务状态${RESET}"
    echo -e "${GREEN}5) 重启 Docker 服务${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    echo -e "${GREEN}==============================${RESET}"
    printf "${GREEN}请选择: ${RESET}"
    read choice
    case $choice in
        1) install_docker ;;
        2) update_docker ;;
        3) uninstall_docker ;;
        4) check_status ;;
        5) restart_docker ;;
        0) exit 0 ;;
        *) warn "无效选项"; pause ;;
    esac
    show_menu
}

show_menu
