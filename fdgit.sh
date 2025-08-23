#!/bin/bash

CONTAINER_NAME="gh-proxy-py"
IMAGE_NAME="hunsh/gh-proxy-py:latest"

green="\033[32m"
red="\033[31m"
yellow="\033[33m"
reset="\033[0m"

# 获取公网 IP，保证输出纯 IP
get_ip() {
  IP=$(curl -s https://api.ip.sb/ip)
  if [ -z "$IP" ]; then
    IP=$(curl -s https://api.ipify.org)
  fi
  if [ -z "$IP" ]; then
    IP=$(hostname -I | awk '{print $1}')
  fi
}

menu() {
  clear
  echo -e "${green}====== gh-proxy-py Docker 管理脚本 ======${reset}"
  echo -e "${green}1.${green} 部署并运行容器${reset}"
  echo -e "${green}2.${green} 启动容器${reset}"
  echo -e "${green}3.${green} 停止容器${reset}"
  echo -e "${green}4.${green} 重启容器${reset}"
  echo -e "${green}5.${green} 查看容器日志${reset}"
  echo -e "${green}6.${green} 删除容器${reset}"
  echo -e "${green}7.${green} 修改外部端口并重新部署${reset}"
  echo -e "${green}8.${green} 查看运行状态${reset}"
  echo -e "${green}9.${green} 更新镜像并重新部署${reset}"
  echo -e "${green}0.${green} 退出${reset}"
  echo -e "${green}=====================================${reset}"
}

deploy_container() {
  read -p "请输入要映射的外部端口 (默认 80): " PORT
  PORT=${PORT:-80}
  docker rm -f $CONTAINER_NAME >/dev/null 2>&1
  echo -e "${yellow}正在部署容器，外部端口映射为 $PORT ...${reset}"
  docker run -d --name="$CONTAINER_NAME" \
    -p 0.0.0.0:$PORT:80 \
    --restart=always \
    $IMAGE_NAME
  if [ $? -eq 0 ]; then
    get_ip
    echo -e "${green}容器已成功运行！访问地址：http://$IP:$PORT${reset}"
  else
    echo -e "${red}部署失败，请检查 Docker 是否正常运行${reset}"
  fi
}

check_status() {
  if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo -e "${green}容器状态:${reset}"
    docker ps -a --filter "name=$CONTAINER_NAME"
  else
    echo -e "${red}容器 $CONTAINER_NAME 未安装${reset}"
  fi
}

update_image() {
  echo -e "${yellow}正在拉取最新镜像...${reset}"
  docker pull $IMAGE_NAME
  echo -e "${yellow}更新完成，正在重新部署...${reset}"
  deploy_container
}

while true; do
  menu
  read -p "请选择操作: " choice
  case $choice in
    1) deploy_container ;;
    2) docker start $CONTAINER_NAME && echo -e "${green}容器已启动${reset}" ;;
    3) docker stop $CONTAINER_NAME && echo -e "${green}容器已停止${reset}" ;;
    4) docker restart $CONTAINER_NAME && echo -e "${green}容器已重启${reset}" ;;
    5) docker logs -f $CONTAINER_NAME ;;
    6) docker rm -f $CONTAINER_NAME && echo -e "${green}容器已删除${reset}" ;;
    7) deploy_container ;;
    8) check_status ;;
    9) update_image ;;
    0) echo -e "${green}退出${reset}"; exit 0 ;;
    *) echo -e "${red}无效选项，请重试${reset}" ;;
  esac
  echo -e "\n按任意键返回菜单..."
  read -n 1
done
