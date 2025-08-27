#!/usr/bin/env bash
set -e

# ================== 基本配置 ==================
COMPOSE_FILE="docker-compose.yml"
IMAGE_NAME="2fauth/2fauth:5.0.2"
CONTAINER_NAME="2fauth"
DEFAULT_HOST_PORT=28000
CONTAINER_PORT=8000
DEFAULT_DATA_DIR="./data"

# ================== 颜色 ==================
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; RESET="\033[0m"

# ================== 工具函数 ==================
exists() { command -v "$1" >/dev/null 2>&1; }
log() { echo -e "${GREEN}✓${RESET} $*"; }
warn() { echo -e "${YELLOW}!${RESET} $*"; }
err() { echo -e "${RED}✗${RESET} $*"; }

port_in_use() {
  local p="$1"
  if exists ss; then ss -lnt "( sport = :$p )" | tail -n +2 | grep -q .
  elif exists lsof; then lsof -iTCP -sTCP:LISTEN -P | awk '{print $9}' | grep -q ":$p\$"
  elif exists netstat; then netstat -lnt | awk '{print $4}' | grep -q ":$p\$"
  else return 1; fi
}

ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then err "请以 root 运行。"; exit 1; fi
}

ensure_docker() {
  if exists docker && exists docker-compose; then return; fi
  warn "未检测到 Docker 或 Docker Compose，请手动安装。"
  exit 1
}

# ================== 核心操作 ==================
generate_compose() {
cat > "$COMPOSE_FILE" <<EOF
version: "3"
services:
  $CONTAINER_NAME:
    image: $IMAGE_NAME
    container_name: $CONTAINER_NAME
    user: root
    volumes:
      - $DATA_DIR:/2fauth
    ports:
      - "$HOST_PORT:$CONTAINER_PORT"
    environment:
      - APP_NAME=My2FA
      - AUTHENTICATION_GUARD=web-guard
    restart: unless-stopped
EOF
}

deploy() {
  ensure_docker

  echo -e "${GREEN}当前宿主机端口: ${DEFAULT_HOST_PORT}${RESET}"
  read -rp "如需修改请输入端口(留空保持默认): " HOST_PORT
  HOST_PORT=${HOST_PORT:-$DEFAULT_HOST_PORT}

  echo -e "${GREEN}挂载数据目录: ${DEFAULT_DATA_DIR}${RESET}"
  read -rp "如需修改请输入目录(留空使用默认): " DATA_DIR
  DATA_DIR=${DATA_DIR:-$DEFAULT_DATA_DIR}

  if port_in_use "$HOST_PORT"; then err "端口 ${HOST_PORT} 已被占用。"; read -rp "按回车返回菜单..." _; return; fi

  mkdir -p "$DATA_DIR"
  chmod 700 "$DATA_DIR"
  chown 1000:1000 "$DATA_DIR"

  log "生成 Docker Compose 文件..."
  generate_compose

  log "启动容器..."
  docker-compose -f "$COMPOSE_FILE" down >/dev/null 2>&1 || true
  docker-compose -f "$COMPOSE_FILE" pull
  docker-compose -f "$COMPOSE_FILE" up -d

  show_status
}

start_c() { docker-compose -f "$COMPOSE_FILE" start; log "已启动"; show_status; }
stop_c() { docker-compose -f "$COMPOSE_FILE" stop; log "已停止"; show_status; }
restart_c() { docker-compose -f "$COMPOSE_FILE" restart; log "已重启"; show_status; }
logs_c() { docker-compose -f "$COMPOSE_FILE" logs -f --tail=200; read -rp "按回车返回菜单..." _; }
uninstall() {
  read -rp "确认卸载并删除容器及 Compose 文件？(y/N): " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    docker-compose -f "$COMPOSE_FILE" down
    rm -f "$COMPOSE_FILE"
    log "已卸载。"
  else warn "已取消"; fi
  read -rp "按回车返回菜单..." _
}

show_status() {
  docker-compose -f "$COMPOSE_FILE" ps
  SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  [ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"
  echo -e "${GREEN}访问地址: http://${SERVER_IP}:${HOST_PORT}${RESET}"
  read -rp "按回车返回菜单..." _
}

# ================== 菜单 ==================
menu() {
  echo -e "${GREEN}=== 2FAuth Docker Compose 管理 ===${RESET}"
  echo -e "${GREEN}容器名称:${RESET} ${CONTAINER_NAME}"
  echo -e "${GREEN}默认端口:${RESET} ${DEFAULT_HOST_PORT}"
  echo -e "${GREEN}默认数据目录:${RESET} ${DEFAULT_DATA_DIR}"
  echo
  echo -e "${GREEN}1) 部署/重装${RESET}"
  echo -e "${GREEN}2) 启动${RESET}"
  echo -e "${GREEN}3) 停止${RESET}"
  echo -e "${GREEN}4) 重启${RESET}"
  echo -e "${GREEN}5) 查看日志${RESET}"
  echo -e "${GREEN}6) 状态${RESET}"
  echo -e "${GREEN}7) 卸载${RESET}"
  echo -e "${GREEN}0) 退出${RESET}"
  echo
  read -rp "请选择: " opt
  case "$opt" in
    1) deploy ;;
    2) start_c ;;
    3) stop_c ;;
    4) restart_c ;;
    5) logs_c ;;
    6) show_status ;;
    7) uninstall ;;
    0) exit 0 ;;
    *) warn "无效选项"; read -rp "按回车返回菜单..." _ ;;
  esac
}

# ================== 入口 ==================
ensure_root
ensure_docker
while true; do menu; done
