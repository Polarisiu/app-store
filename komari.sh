#!/bin/bash

CONTAINER_NAME="komari"
IMAGE_NAME="ghcr.io/komari-monitor/komari:latest"
DATA_DIR="./data"
PORT=25774
GREEN="\033[32m"
RESET="\033[0m"

# 获取服务器公网IP
get_ip() {
  curl -s ifconfig.me || echo "你的服务器IP"
}

# 检查容器状态
get_status() {
  if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}运行中${RESET}"
  elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${GREEN}已停止${RESET}"
  else
    echo -e "${GREEN}未安装${RESET}"
  fi
}

# 运行容器
run_container() {
  mkdir -p $DATA_DIR
  if [ -n "$ADMIN_USERNAME" ] && [ -n "$ADMIN_PASSWORD" ]; then
    docker run -d \
      -p ${PORT}:25774 \
      -v $(pwd)/${DATA_DIR}:/app/data \
      -e ADMIN_USERNAME=$ADMIN_USERNAME \
      -e ADMIN_PASSWORD=$ADMIN_PASSWORD \
      --name ${CONTAINER_NAME} \
      ${IMAGE_NAME}
  else
    docker run -d \
      -p ${PORT}:25774 \
      -v $(pwd)/${DATA_DIR}:/app/data \
      --name ${CONTAINER_NAME} \
      ${IMAGE_NAME}
  fi
}

pause() {
  echo
  read -p "按回车键返回菜单..." temp
}

menu() {
  clear
  echo -e "${GREEN}===== Komari Docker 管理脚本 =====${RESET}"
  echo -e "容器状态: $(get_status)"
  echo -e "当前端口: ${PORT}"
  echo -e "管理员账号: ${ADMIN_USERNAME:-默认}"
  echo -e "管理员密码: ${ADMIN_PASSWORD:-默认}"
  echo -e "${GREEN}=================================${RESET}"
  echo -e "${GREEN}1.${RESET} 启动 Komari"
  echo -e "${GREEN}2.${RESET} 停止 Komari"
  echo -e "${GREEN}3.${RESET} 重启 Komari"
  echo -e "${GREEN}4.${RESET} 查看日志"
  echo -e "${GREEN}5.${RESET} 更新 Komari"
  echo -e "${GREEN}6.${RESET} 卸载 Komari"
  echo -e "${GREEN}7.${RESET} 修改管理员账号密码"
  echo -e "${GREEN}8.${RESET} 修改端口号"
  echo -e "${GREEN}9.${RESET} 退出"
  echo -e "${GREEN}=================================${RESET}"
  read -p "请选择操作 [1-9]: " choice

  case $choice in
    1)
      run_container
      echo -e "${GREEN}✅ Komari 已启动${RESET}"
      echo -e "访问地址: ${GREEN}http://$(get_ip):${PORT}${RESET}"
      pause
      ;;
    2)
      docker stop ${CONTAINER_NAME}
      echo -e "${GREEN}🛑 Komari 已停止${RESET}"
      pause
      ;;
    3)
      docker restart ${CONTAINER_NAME}
      echo -e "${GREEN}🔄 Komari 已重启${RESET}"
      echo -e "访问地址: ${GREEN}http://$(get_ip):${PORT}${RESET}"
      pause
      ;;
    4)
      docker logs -f ${CONTAINER_NAME}
      ;;
    5)
      echo -e "${GREEN}⬇️ 正在更新 Komari ...${RESET}"
      docker pull ${IMAGE_NAME}
      docker stop ${CONTAINER_NAME}
      docker rm ${CONTAINER_NAME}
      run_container
      echo -e "${GREEN}✅ Komari 已更新并重新启动${RESET}"
      echo -e "访问地址: ${GREEN}http://$(get_ip):${PORT}${RESET}"
      pause
      ;;
    6)
      docker stop ${CONTAINER_NAME}
      docker rm ${CONTAINER_NAME}
      echo -e "${GREEN}🗑️ Komari 已卸载 (数据目录 ${DATA_DIR} 未删除)${RESET}"
      pause
      ;;
    7)
      read -p "请输入管理员用户名: " ADMIN_USERNAME
      read -sp "请输入管理员密码: " ADMIN_PASSWORD
      echo
      echo -e "${GREEN}✅ 已设置管理员账号密码，正在重启容器...${RESET}"
      docker stop ${CONTAINER_NAME} >/dev/null 2>&1
      docker rm ${CONTAINER_NAME} >/dev/null 2>&1
      run_container
      echo -e "${GREEN}🔑 管理员账号已更新${RESET}"
      echo -e "访问地址: ${GREEN}http://$(get_ip):${PORT}${RESET}"
      pause
      ;;
    8)
      read -p "请输入新的端口号 (默认 25774): " NEW_PORT
      if [[ "$NEW_PORT" =~ ^[0-9]+$ ]]; then
        PORT=$NEW_PORT
        echo -e "${GREEN}✅ 已修改端口号为: $PORT，下次启动/更新将使用${RESET}"
      else
        echo -e "${GREEN}❌ 端口号必须是数字${RESET}"
      fi
      pause
      ;;
    9)
      exit 0
      ;;
    *)
      echo -e "${GREEN}❌ 无效选择，请重新输入${RESET}"
      pause
      ;;
  esac
}

while true; do
  menu
done
