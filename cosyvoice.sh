#!/bin/bash
# ========================================
# CosyVoice 一键管理脚本 (Docker Compose)
# ========================================

APP_NAME="cosyvoice"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

menu() {
  clear
  echo -e "${GREEN}=== CosyVoice 管理菜单 ===${RESET}"
  echo -e "${GREEN}1) 安装启动${RESET}"
  echo -e "${GREEN}2) 更新${RESET}"
  echo -e "${GREEN}3) 重启${RESET}"
  echo -e "${GREEN}4) 查看日志${RESET}"
  echo -e "${GREEN}5) 卸载(含数据)${RESET}"
  echo -e "${GREEN}0) 退出${RESET}"
  read -rp "$(echo -e ${GREEN}请选择: ${RESET})" choice
  case $choice in
    1) install_app ;;
    2) update_app ;;
    3) restart_app ;;
    4) view_logs ;;
    5) uninstall_app ;;
    0) exit 0 ;;
    *) echo -e "${RED}无效选择${RESET}"; sleep 1; menu ;;
  esac
}

install_app() {
  mkdir -p "$APP_DIR"

  read -p "请输入宿主机映射端口 [默认:50000]: " input_port
  PORT=${input_port:-50000}

  read -p "请选择架构（1: amd64 / 2: arm，默认 amd64）: " arch_choice
  case $arch_choice in
    2) IMAGE="eureka6688/cosyvoice:arm" ;;
    *) IMAGE="eureka6688/cosyvoice:latest" ;;
  esac

  cat > "$COMPOSE_FILE" <<EOF
services:
  cov:
    image: $IMAGE
    container_name: cov
    ports:
      - "127.0.0.1:${PORT}:50000"
    command: ["python", "web.py", "--port", "50000"]
    stdin_open: true
    tty: true
    restart: unless-stopped
EOF

  cd "$APP_DIR"
  docker compose up -d

  echo -e "${GREEN}✅ CosyVoice 已安装并启动${RESET}"
  echo -e "${YELLOW}🌐 Web UI 地址: http://127.0.0.1:${PORT}${RESET}"
  echo -e "${GREEN}📂 数据目录: $APP_DIR${RESET}"
  read -p "按回车返回菜单..."
  menu
}

update_app() {
  cd "$APP_DIR" || { echo "❌ 未检测到安装目录"; sleep 1; menu; }
  docker compose pull
  docker compose up -d
  echo -e "${GREEN}✅ CosyVoice 已更新并重启${RESET}"
  read -p "按回车返回菜单..."
  menu
}

restart_app() {
  cd "$APP_DIR" || { echo "❌ 未检测到安装目录"; sleep 1; menu; }
  docker compose restart
  echo -e "${GREEN}✅ CosyVoice 已重启${RESET}"
  read -p "按回车返回菜单..."
  menu
}

view_logs() {
  docker logs -f cov
  read -p "按回车返回菜单..."
  menu
}

uninstall_app() {
  cd "$APP_DIR" || { echo "❌ 未检测到安装目录"; sleep 1; menu; }
  docker compose down -v
  rm -rf "$APP_DIR"
  echo -e "${RED}✅ CosyVoice 已卸载并删除所有数据${RESET}"
  read -p "按回车返回菜单..."
  menu
}

menu
