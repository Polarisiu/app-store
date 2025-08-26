#!/bin/bash
set -e

# ================== 颜色 ==================
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# ================== 默认配置 ==================
DATA_DIR="/opt/newapi"
API_IMAGE="calciumion/new-api:latest"
API_CONTAINER="new-api"
MYSQL_CONTAINER="newapi-mysql"
MYSQL_ROOT_PASSWORD="123456"
MYSQL_DB="newapi"
MYSQL_USER="newapi"
MYSQL_PASSWORD="123456"
API_PORT=3000

# ================== 工具函数 ==================
pause() { read -p "按回车键继续..." }

show_ip_port() {
    IP=$(hostname -I | awk '{print $1}')
    echo -e "${GREEN}访问地址: http://${IP}:${API_PORT}${RESET}"
}

generate_env() {
    mkdir -p $DATA_DIR
    cat > $DATA_DIR/.env <<EOF
MYSQL_HOST=$MYSQL_CONTAINER
MYSQL_PORT=3306
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_DB=$MYSQL_DB
TZ=Asia/Shanghai
EOF
    echo -e "${GREEN}.env 文件已生成${RESET}"
}

init_database() {
    echo -e "${GREEN}检测 MySQL 数据库是否已初始化...${RESET}"
    docker exec -i $MYSQL_CONTAINER mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "USE $MYSQL_DB;" 2>/dev/null || {
        echo -e "${GREEN}数据库未初始化，正在初始化...${RESET}"
        docker exec -i $MYSQL_CONTAINER mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF
        echo -e "${GREEN}数据库初始化完成${RESET}"
    }
}

install_api() {
    read -p "请输入 New API 端口(默认 $API_PORT): " port
    API_PORT=${port:-$API_PORT}

    generate_env

    echo -e "${GREEN}正在启动 MySQL 容器...${RESET}"
    docker run --name $MYSQL_CONTAINER -d --restart always \
        -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
        -e MYSQL_DATABASE=$MYSQL_DB \
        -e MYSQL_USER=$MYSQL_USER \
        -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
        -v $DATA_DIR/mysql:/var/lib/mysql \
        mysql:8

    echo -e "${GREEN}等待 MySQL 启动...${RESET}"
    sleep 15

    init_database

    echo -e "${GREEN}正在启动 New API 容器...${RESET}"
    docker run --name $API_CONTAINER -d --restart always \
        --env-file $DATA_DIR/.env \
        -p ${API_PORT}:${API_PORT} \
        -v $DATA_DIR:/data \
        $API_IMAGE

    echo -e "${GREEN}安装完成${RESET}"
    show_ip_port
    pause
}

uninstall_api() {
    echo -e "${RED}停止并删除 New API 容器...${RESET}"
    docker rm -f $API_CONTAINER || true
    docker rm -f $MYSQL_CONTAINER || true
    echo -e "${RED}删除数据目录 ${DATA_DIR} ? (y/n)${RESET}"
    read ans
    if [[ $ans == [Yy] ]]; then
        rm -rf $DATA_DIR
        echo -e "${RED}数据已删除${RESET}"
    fi
    pause
}

update_api() {
    echo -e "${GREEN}拉取最新镜像...${RESET}"
    docker pull $API_IMAGE
    docker stop $API_CONTAINER
    docker rm $API_CONTAINER
    docker run --name $API_CONTAINER -d --restart always \
        --env-file $DATA_DIR/.env \
        -p ${API_PORT}:${API_PORT} \
        -v $DATA_DIR:/data \
        $API_IMAGE
    echo -e "${GREEN}更新完成${RESET}"
    pause
}

start_api() { docker start $API_CONTAINER && echo -e "${GREEN}已启动${RESET}" && pause }
stop_api() { docker stop $API_CONTAINER && echo -e "${RED}已停止${RESET}" && pause }
restart_api() { stop_api; start_api; }

view_api_logs() { docker logs -f $API_CONTAINER; pause }
view_mysql_logs() { docker logs -f $MYSQL_CONTAINER; pause }

menu() {
    while true; do
        clear
        echo -e "${GREEN}===== New API 管理菜单 =====${RESET}"
        echo -e "${GREEN}1.${RESET} 安装 New API"
        echo -e "${GREEN}2.${RESET} 卸载 New API"
        echo -e "${GREEN}3.${RESET} 更新 New API"
        echo -e "${GREEN}4.${RESET} 启动 New API"
        echo -e "${GREEN}5.${RESET} 停止 New API"
        echo -e "${GREEN}6.${RESET} 重启 New API"
        echo -e "${GREEN}7.${RESET} 查看 New API 日志"
        echo -e "${GREEN}8.${RESET} 查看 MySQL 日志"
        echo -e "${GREEN}9.${RESET} 显示访问 IP + 端口"
        echo -e "${GREEN}0.${RESET} 退出"
        read -p "请输入编号: " choice
        case $choice in
            1) install_api ;;
            2) uninstall_api ;;
            3) update_api ;;
            4) start_api ;;
            5) stop_api ;;
            6) restart_api ;;
            7) view_api_logs ;;
            8) view_mysql_logs ;;
            9) show_ip_port ;;
            0) exit ;;
            *) echo -e "${RED}输入错误${RESET}" && pause ;;
        esac
    done
}

menu
