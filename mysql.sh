#!/bin/bash
# MySQL Docker 管理菜单

# 颜色定义
GREEN="\033[32m"
RESET="\033[0m"

CONTAINER_NAME="mysql8"
MYSQL_ROOT_PASSWORD="123456"
MYSQL_DATABASE="mydb"
MYSQL_USER="myuser"
MYSQL_PASSWORD="mypassword"
MYSQL_VERSION="8.0"
DATA_DIR="/opt/mysql/data"
CONF_DIR="/opt/mysql/conf"

function show_access_info() {
    HOST_IP=$(hostname -I | awk '{print $1}')
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📌 访问地址: $HOST_IP:3306"
    echo "👤 root 用户: root"
    echo "🔑 root 密码: $MYSQL_ROOT_PASSWORD"
    echo "👤 默认数据库用户: $MYSQL_USER"
    echo "🔑 默认用户密码: $MYSQL_PASSWORD"
    echo "🗄 预设数据库: $MYSQL_DATABASE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

function install_mysql() {
    mkdir -p "$DATA_DIR" "$CONF_DIR"

    # 创建 utf8mb4 配置文件
    cat > "$CONF_DIR/my.cnf" <<'EOF'
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_general_ci

[client]
default-character-set=utf8mb4

[mysql]
default-character-set=utf8mb4
EOF

    docker run --name $CONTAINER_NAME \
        -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
        -e MYSQL_DATABASE=$MYSQL_DATABASE \
        -e MYSQL_USER=$MYSQL_USER \
        -e MYSQL_PASSWORD=$MYSQL_PASSWORD \
        -p 3306:3306 \
        -v $DATA_DIR:/var/lib/mysql \
        -v $CONF_DIR:/etc/mysql/conf.d \
        --restart unless-stopped \
        -d mysql:$MYSQL_VERSION

    echo -e "${GREEN}✅ MySQL 容器已启动${RESET}"
    show_access_info
}

function start_mysql() {
    docker start $CONTAINER_NAME
    echo -e "${GREEN}✅ MySQL 容器已启动${RESET}"
    show_access_info
}

function stop_mysql() {
    docker stop $CONTAINER_NAME
}

function restart_mysql() {
    docker restart $CONTAINER_NAME
}

function logs_mysql() {
    docker logs -f $CONTAINER_NAME
}

function remove_mysql_keep_data() {
    docker rm -f $CONTAINER_NAME
    echo -e "${GREEN}✅ 容器已删除，数据保留在 $DATA_DIR${RESET}"
}

function remove_mysql_and_data() {
    docker rm -f $CONTAINER_NAME
    rm -rf "$DATA_DIR" "$CONF_DIR"
    echo -e "${GREEN}✅ 容器和数据已删除${RESET}"
}

function create_database() {
    read -p "$(echo -e ${GREEN}请输入新数据库名:${RESET} )" new_db
    read -p "$(echo -e ${GREEN}请输入字符集(默认utf8mb4):${RESET} )" charset
    charset=${charset:-utf8mb4}

    docker exec -i $CONTAINER_NAME \
        mysql -uroot -p$MYSQL_ROOT_PASSWORD \
        -e "CREATE DATABASE IF NOT EXISTS \`$new_db\` CHARACTER SET $charset COLLATE ${charset}_general_ci;"

    echo -e "${GREEN}✅ 数据库 '$new_db' 已创建 (字符集: $charset)${RESET}"
}

function create_user_and_grant() {
    read -p "$(echo -e ${GREEN}请输入新用户名:${RESET} )" new_user
    read -p "$(echo -e ${GREEN}请输入新用户密码:${RESET} )" new_pass
    read -p "$(echo -e ${GREEN}请输入要授权的数据库名:${RESET} )" grant_db

    docker exec -i $CONTAINER_NAME \
        mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE USER IF NOT EXISTS '$new_user'@'%' IDENTIFIED BY '$new_pass';
GRANT ALL PRIVILEGES ON \`$grant_db\`.* TO '$new_user'@'%';
FLUSH PRIVILEGES;
EOF

    echo -e "${GREEN}✅ 用户 '$new_user' 已创建，并对数据库 '$grant_db' 授予全部权限${RESET}"
}

function create_db_user_grant_all() {
    read -p "$(echo -e ${GREEN}请输入新数据库名:${RESET} )" new_db
    read -p "$(echo -e ${GREEN}请输入字符集(默认utf8mb4):${RESET} )" charset
    charset=${charset:-utf8mb4}
    read -p "$(echo -e ${GREEN}请输入新用户名:${RESET} )" new_user
    read -p "$(echo -e ${GREEN}请输入新用户密码:${RESET} )" new_pass

    docker exec -i $CONTAINER_NAME \
        mysql -uroot -p$MYSQL_ROOT_PASSWORD <<EOF
CREATE DATABASE IF NOT EXISTS \`$new_db\` CHARACTER SET $charset COLLATE ${charset}_general_ci;
CREATE USER IF NOT EXISTS '$new_user'@'%' IDENTIFIED BY '$new_pass';
GRANT ALL PRIVILEGES ON \`$new_db\`.* TO '$new_user'@'%';
FLUSH PRIVILEGES;
EOF

    echo -e "${GREEN}✅ 数据库 '$new_db' 已创建 (字符集: $charset)${RESET}"
    echo -e "${GREEN}✅ 用户 '$new_user' 已创建，并拥有数据库 '$new_db' 的全部权限${RESET}"
}

while true; do
    clear
    echo -e "${GREEN}=== MySQL Docker 管理菜单 ===${RESET}"
    echo -e "${GREEN}1. 安装并启动 MySQL (持久化 & UTF8MB4)${RESET}"
    echo -e "${GREEN}2. 启动 MySQL${RESET}"
    echo -e "${GREEN}3. 停止 MySQL${RESET}"
    echo -e "${GREEN}4. 重启 MySQL${RESET}"
    echo -e "${GREEN}5. 查看 MySQL 日志${RESET}"
    echo -e "${GREEN}6. 删除容器 (保留数据)${RESET}"
    echo -e "${GREEN}7. 删除容器和数据${RESET}"
    echo -e "${GREEN}8. 创建新数据库${RESET}"
    echo -e "${GREEN}9. 创建用户并授权${RESET}"
    echo -e "${GREEN}10. 一键创建数据库+用户+授权${RESET}"
    echo -e "${GREEN}11. 查看访问地址${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "${GREEN}===========================${RESET}"
    read -p "$(echo -e ${GREEN}请输入选项:${RESET} )" choice

    case $choice in
        1) install_mysql ;;
        2) start_mysql ;;
        3) stop_mysql ;;
        4) restart_mysql ;;
        5) logs_mysql ;;
        6) remove_mysql_keep_data ;;
        7) remove_mysql_and_data ;;
        8) create_database ;;
        9) create_user_and_grant ;;
        10) create_db_user_grant_all ;;
        11) show_access_info ;;
        0) exit 0 ;;
        *) echo "❌ 无效选项" ;;
    esac

    read -p "$(echo -e ${GREEN}按回车继续...${RESET})"
done
