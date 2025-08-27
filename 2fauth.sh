#!/usr/bin/env bash
set -e

# ================== 基本配置 ==================
IMAGE_NAME="2fauth/2fauth"
CONTAINER_NAME="2fauth"
CONF_FILE="/etc/2fauth.conf"
DEFAULT_PORT=8120
CONTAINER_PORT=8000
DEFAULT_APP_URL="https://2fa.gugu.ovh"

# 默认挂载目录
DATA_DIR="./data"
DB_DIR="./database"

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
  if exists docker; then return; fi
  warn "未检测到 Docker，请手动安装后再运行。"
  exit 1
}

load_or_init_conf() {
  HOST_PORT="$DEFAULT_PORT"
  APP_URL="$DEFAULT_APP_URL"
  APP_KEY=""
  if [ -f "$CONF_FILE" ]; then . "$CONF_FILE"; else echo -e "HOST_PORT=$DEFAULT_PORT\nAPP_URL=$DEFAULT_APP_URL" > "$CONF_FILE"; fi
}

save_conf() { echo -e "HOST_PORT=$HOST_PORT\nAPP_URL=$APP_URL\nAPP_KEY=$APP_KEY" > "$CONF_FILE"; }

show_status() {
  if docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    docker ps -a --filter "name=^/${CONTAINER_NAME}$" --format \
"容器: {{.Names}} | 镜像: {{.Image}} | 状态: {{.Status}} | 端口: {{.Ports}}"
  else warn "未发现容器 $CONTAINER_NAME"; fi
  read -rp "按回车返回菜单..." _
}

# ================== 核心操作 ==================
generate_app_key() {
  # 生成32字符随机字符串
  APP_KEY=$(head -c 48 /dev/urandom | base64 | tr -d '=+/' | cut -c1-32)
}

deploy() {
  load_or_init_conf
  echo -e "${GREEN}当前端口: ${HOST_PORT}${RESET}"
  read -rp "如需修改请输入新端口(留空保持 ${HOST_PORT}): " newp
  [ -n "$newp" ] && HOST_PORT="$newp"

  echo -e "${GREEN}当前 APP_URL: ${APP_URL}${RESET}"
  read -rp "如需修改请输入新的 APP_URL (留空保持默认): " new_url
  [ -n "$new_url" ] && APP_URL="$new_url"

  # APP_KEY 自定义或随机
  generate_app_key
  echo -e "${GREEN}当前 APP_KEY: ${APP_KEY}${RESET}"
  read -rp "如需自定义请输入 APP_KEY (留空使用默认随机值): " key_input
  [ -n "$key_input" ] && APP_KEY="$key_input"

  if port_in_use "$HOST_PORT"; then err "端口 ${HOST_PORT} 已被占用。"; read -rp "按回车返回菜单..." _; return; fi
  ensure_docker

  # 确保挂载目录存在
  mkdir -p "$DATA_DIR" "$DB_DIR"

  # 修改目录所有者和权限
  chown 1000:1000 "$DATA_DIR" "$DB_DIR"
  chmod 700 "$DATA_DIR" "$DB_DIR"

  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
  log "拉取镜像：$IMAGE_NAME"
  docker pull "$IMAGE_NAME"

  log "创建并启动容器：$CONTAINER_NAME (映射 ${HOST_PORT}:${CONTAINER_PORT})"
  docker run -d --restart unless-stopped --name "$CONTAINER_NAME" \
    -v "$DATA_DIR":/2fauth \
    -v "$DB_DIR":/srv/database \
    -p "${HOST_PORT}:${CONTAINER_PORT}" \
    -e APP_NAME=2FAuth \
    -e APP_KEY="$APP_KEY" \
    -e APP_URL="$APP_URL" \
    -e IS_DEMO_APP=false \
    -e LOG_CHANNEL=daily \
    -e LOG_LEVEL=notice \
    -e DB_DATABASE="/srv/database/database.sqlite" \
    -e CACHE_DRIVER=file \
    -e SESSION_DRIVER=file \
    -e AUTHENTICATION_GUARD=web-guard \
    "$IMAGE_NAME"

  save_conf
  show_status

  SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  [ -z "$SERVER_IP" ] && SERVER_IP="127.0.0.1"
  echo -e "${GREEN}访问地址: http://${SERVER_IP}:${HOST_PORT}${RESET}"
  echo -e "${GREEN}使用的 APP_KEY: ${APP_KEY}${RESET}"

  read -rp "按回车返回菜单..." _
}

start_c() { docker start "$CONTAINER_NAME" && log "已启动。" || err "启动失败。"; read -rp "按回车返回菜单..." _; }
stop_c() { docker stop "$CONTAINER_NAME" && log "已停止。" || err "停止失败。"; read -rp "按回车返回菜单..." _; }
restart_c() { docker restart "$CONTAINER_NAME" && log "已重启。" || err "重启失败。"; read -rp "按回车返回菜单..." _; }
logs_c() { docker logs -f --tail=200 "$CONTAINER_NAME"; read -rp "按回车返回菜单..." _; }

update_c() {
  ensure_docker
  load_or_init_conf

  generate_app_key
  echo -e "${GREEN}当前 APP_KEY: ${APP_KEY}${RESET}"
  read -rp "如需自定义请输入 APP_KEY (留空使用默认随机值): " key_input
  [ -n "$key_input" ] && APP_KEY="$key_input"

  log "拉取最新镜像..."
  docker pull "$IMAGE_NAME"
  warn "重启容器应用最新镜像..."
  docker restart "$CONTAINER_NAME"
  show_status
  echo -e "${GREEN}使用的 APP_KEY: ${APP_KEY}${RESET}"
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
  echo -e "${GREEN}=== 2FAuth 管理脚本 ===${RESET}"
  echo -e "${GREEN}容器名称:${RESET} ${CONTAINER_NAME}"
  [ -f "$CONF_FILE" ] && . "$CONF_FILE" || true
  [ -n "$HOST_PORT" ] && echo -e "${GREEN}访问端口:${RESET} ${HOST_PORT}"
  [ -n "$APP_URL" ] && echo -e "${GREEN}APP_URL:${RESET} ${APP_URL}"
  [ -n "$APP_KEY" ] && echo -e "${GREEN}APP_KEY:${RESET} ${APP_KEY}"
  echo
  echo -e "${GREEN}1) 部署/重装${RESET}"
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
