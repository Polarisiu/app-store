#!/bin/bash

# ================== 颜色 ==================
GREEN="\033[32m"
RESET="\033[0m"

CONTAINER_NAME="HubP"
IMAGE_NAME="ymyuuu/hubp:latest"
DATA_DIR="/root/hubp_data"

# 确保数据目录存在
mkdir -p $DATA_DIR

# ================== 菜单 ==================
while true; do
    echo -e "${GREEN}================ HubP 管理脚本 ================${RESET}"
    echo -e "${GREEN}1.启动容器${RESET}"
    echo -e "${GREEN}2.停止容器${RESET}"
    echo -e "${GREEN}3.更新容器${RESET}"
    echo -e "${GREEN}4.查看日志${RESET}"
    echo -e "${GREEN}5.卸载容器${RESET}"
    echo -e "${GREEN}0.退出脚本${RESET}"
    echo -ne "${GREEN}请输入选项: ${RESET}"
    read choice

    case "$choice" in
        1)
            if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
                echo -e "${GREEN}容器已在运行，无需重复启动！${RESET}"
            else
                if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
                    echo -e "${GREEN}容器已存在，启动中...${RESET}"
                    docker start $CONTAINER_NAME
                    echo -e "${GREEN}启动完成！${RESET}"
                else
                    echo -ne "${GREEN}请输入宿主机端口（默认 18184）: ${RESET}"
                    read PORT
                    PORT=${PORT:-18184}

                    echo -ne "${GREEN}请输入 HUBP_DISGUISE（默认 onlinealarmkur.com）: ${RESET}"
                    read DISGUISE
                    DISGUISE=${DISGUISE:-onlinealarmkur.com}

                    echo -e "${GREEN}启动 HubP 容器...${RESET}"
                    docker run -d --restart unless-stopped --name $CONTAINER_NAME \
                        -p $PORT:18184 \
                        -v $DATA_DIR:/app/data \
                        -e HUBP_LOG_LEVEL=debug \
                        -e HUBP_DISGUISE=$DISGUISE \
                        $IMAGE_NAME
                    echo -e "${GREEN}启动完成！${RESET}"
                fi
            fi
            echo -ne "${GREEN}按回车返回菜单...${RESET}"
            read
            ;;
        2)
            if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
                docker stop $CONTAINER_NAME
                echo -e "${GREEN}容器已停止！${RESET}"
            else
                echo -e "${GREEN}容器未运行！${RESET}"
            fi
            echo -ne "${GREEN}按回车返回菜单...${RESET}"
            read
            ;;
        3)
            echo -e "${GREEN}更新 HubP 容器（拉取镜像 + 重启）...${RESET}"
            docker pull $IMAGE_NAME
            if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
                docker restart $CONTAINER_NAME
                echo -e "${GREEN}更新完成并重启容器！${RESET}"
            else
                echo -ne "${GREEN}容器不存在，是否现在启动？(y/N): ${RESET}"
                read yn
                if [[ "$yn" =~ ^[Yy]$ ]]; then
                    echo -ne "${GREEN}请输入宿主机端口（默认 18184）: ${RESET}"
                    read PORT
                    PORT=${PORT:-18184}

                    echo -ne "${GREEN}请输入 HUBP_DISGUISE（默认 onlinealarmkur.com）: ${RESET}"
                    read DISGUISE
                    DISGUISE=${DISGUISE:-onlinealarmkur.com}

                    docker run -d --restart unless-stopped --name $CONTAINER_NAME \
                        -p $PORT:18184 \
                        -v $DATA_DIR:/app/data \
                        -e HUBP_LOG_LEVEL=debug \
                        -e HUBP_DISGUISE=$DISGUISE \
                        $IMAGE_NAME
                    echo -e "${GREEN}容器已启动！${RESET}"
                fi
            fi
            echo -ne "${GREEN}按回车返回菜单...${RESET}"
            read
            ;;
        4)
            if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
                echo -e "${GREEN}查看日志，按 Ctrl+C 退出...${RESET}"
                docker logs -f $CONTAINER_NAME
            else
                echo -e "${GREEN}容器未运行，无法查看日志！${RESET}"
            fi
            echo -ne "${GREEN}按回车返回菜单...${RESET}"
            read
            ;;
        5)
            if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
                echo -ne "${GREEN}确定要卸载容器吗？(y/N): ${RESET}"
                read yn
                if [[ "$yn" =~ ^[Yy]$ ]]; then
                    docker stop $CONTAINER_NAME >/dev/null 2>&1
                    docker rm $CONTAINER_NAME >/dev/null 2>&1
                    echo -ne "${GREEN}是否删除数据目录 $DATA_DIR？(y/N): ${RESET}"
                    read deldata
                    if [[ "$deldata" =~ ^[Yy]$ ]]; then
                        rm -rf $DATA_DIR
                        echo -e "${GREEN}数据目录已删除！${RESET}"
                    fi
                    echo -e "${GREEN}卸载完成！${RESET}"
                fi
            else
                echo -e "${GREEN}容器不存在，无需卸载！${RESET}"
            fi
            echo -ne "${GREEN}按回车返回菜单...${RESET}"
            read
            ;;
        0)
            echo -e "${GREEN}退出脚本${RESET}"
            exit 0
            ;;
        *)
            echo -e "${GREEN}无效选项，请重新输入！${RESET}"
            ;;
    esac
done
