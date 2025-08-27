#!/usr/bin/env bash
set -e

# ================== 基本配置 ==================
IMAGE_NAME="youshandefeiyang/sub-web-modify"
CONTAINER_NAME="sub-web-modify"
CONF_FILE="/etc/sub-web-modify.conf"
DEFAULT_PORT=8090
CONTAINER_PORT=80

# ================== 颜色 ==================
GREEN="\033[32m"; YELLOW="\033[33m"; RED="\033[31m"; CYAN="\033[36m"; RESET="\033[0m"

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
  if exists docker; then return; fi
  warn "未检测到 Docker，请手动安装后再运行。"
  exit 1
}

load_or_init_conf() {
  HOST_PORT="$DEFAULT_PORT"
  if [ -f "$CONF_FILE" ]; then . "$CONF_FILE"; else echo "HOST_PORT=$DEFAULT_PORT" > "$CONF_FILE"; fi
}

save_conf() { echo "HOST_PORT=$HOST_PORT" > "$CONF_FILE"; }

show_status() {
  if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format \
"容器: {{.Names}} | 镜像: {{.Image}} | 状态: {{.Status}} | 端口: {{.Ports}}"
  else warn "未发现容器 $CONTAINER_NAME"; fi
  read -rp "按回车返回菜单..." _
}

# ================== 核心操作 ==================
deploy() {
  load_or_init_conf
  echo -e "${GREEN}当前端口: ${HOST_PORT}${RESET}"
  read -rp "如需修改请输入新端口(留空保持 ${HOST_PORT}): " newp
  [ -n "$newp" ] && HOST_PORT="$newp"

  if port_in_use "$HOST_PORT"; then err "端口 ${HOST_PORT} 已被占用。"; read -rp "按回车返回菜单..." _; return; fi
  ensure_docker

  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  log "拉取镜像：$IMAGE_NAME"
  docker pull "$IMAGE_NAME"

  log "创建并启动容器：$CONTAINER_NAME (映射 ${HOST_PORT}:${CONTAINER_PORT})"
  docker run -d --restart unless-stopped --name "$CONTAINER_NAME" \
    -p "${HOST_PORT}:${CONTAINER_PORT}" "$IMAGE_NAME"

  save_conf
  show_status

  SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  [ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"
  echo -e "${GREEN}访问地址: http://${SERVER_IP}:${HOST_PORT}${RESET}"

  read -rp "按回车返回菜单..." _
}

start_c() { docker start "$CONTAINER_NAME" && log "已启动。" || err "启动失败。"; read -rp "按回车返回菜单..." _; }
stop_c() { docker stop "$CONTAINER_NAME" && log "已停止。" || err "停止失败。"; read -rp "按回车返回菜单..." _; }
restart_c() { docker restart "$CONTAINER_NAME" && log "已重启。" || err "重启失败。"; read -rp "按回车返回菜单..." _; }
logs_c() { docker logs -f --tail=200 "$CONTAINER_NAME"; read -rp "按回车返回菜单..." _; }

update_c() {
  ensure_docker
  load_or_init_conf
  log "拉取最新镜像..."
  docker pull "$IMAGE_NAME"
  warn "重启容器应用最新镜像..."
  docker restart "$CONTAINER_NAME"
  show_status
  read -rp "按回车返回菜单..." _
}

uninstall() {
  read -rp "确认卸载并删除容器？(y/N): " yn
  if [[ "$yn" =~ ^[Yy]$ ]]; then
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    read -rp "是否同时删除镜像 ${IMAGE_NAME}？(y/N): " yn2
    if [[ "$yn2" =~ ^[Yy]$ ]]; then
      docker rmi "$IMAGE_NAME" || true
    fi
    rm -f "$CONF_FILE"
    log "已卸载。"
  else warn "已取消。"; fi
  read -rp "按回车返回菜单..." _
}

# ================== 菜单 ==================
menu() {
  echo -e "${GREEN}=== Sub-Web-Modify 管理脚本 ===${RESET}"
  echo -e "${GREEN}容器名称:${RESET} ${CONTAINER_NAME}"
  [ -f "$CONF_FILE" ] && . "$CONF_FILE" || true
  [ -n "$HOST_PORT" ] && echo -e "${GREEN}访问端口:${RESET} ${HOST_PORT}"
  echo
  echo -e "${GREEN}1) 部署${RESET}"
  echo -e "${GREEN}2) 启动${RESET}"
  echo -e "${GREEN}3) 停止${RESET}"
  echo -e "${GREEN}4) 重启${RESET}"
  echo -e "${GREEN}5) 查看日志${RESET}"
  echo -e "${GREEN}6) 更新镜像并重启${RESET}"
  echo -e "${GREEN}7) 状态${RESET}"
  echo -e "${GREEN}8) 卸载${RESET}"
  echo -e "${GREEN}0) 退出${RESET}"
  echo
  read -rp "请选择: " opt
  case "$opt" in
    1) deploy ;;
    2) start_c ;;
    3) stop_c ;;
    4) restart_c ;;
    5) logs_c ;;
    6) update_c ;;
    7) show_status ;;
    8) uninstall ;;
    0) exit 0 ;;
    *) warn "无效选项"; read -rp "按回车返回菜单..." _ ;;
  esac
}

# ================== 入口 ==================
ensure_root
ensure_docker
while true; do menu; done
