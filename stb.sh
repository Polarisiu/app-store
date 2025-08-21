#!/bin/bash
# ========================================
# STB 本地源码一键管理脚本（零环境部署 + Docker MongoDB + 更新 + 卸载）
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

REPO_URL="https://github.com/setube/stb.git"
APP_DIR="stb"
MONGO_HOST=${MONGO_URL:-"mongodb://localhost:27017/stb"}

# ================== 菜单 ==================
function show_menu() {
    echo -e "${CYAN}================= STB 管理脚本 =================${RESET}"
    echo -e "${GREEN}1. 下载源码${RESET}"
    echo -e "${GREEN}2. 安装 Node.js / pnpm / 项目依赖${RESET}"
    echo -e "${GREEN}3. 编译项目${RESET}"
    echo -e "${GREEN}4. 启动项目${RESET}"
    echo -e "${GREEN}5. 查看日志${RESET}"
    echo -e "${GREEN}6. 停止项目${RESET}"
    echo -e "${GREEN}7. 检测 MongoDB${RESET}"
    echo -e "${GREEN}8. 安装 MongoDB(Docker)${RESET}"
    echo -e "${GREEN}9. 卸载项目及环境${RESET}"
    echo -e "${GREEN}10.更新项目${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "${CYAN}==============================================${RESET}"
}

# ================== 功能 ==================
function clone_repo() {
    if [ -d "$APP_DIR" ]; then
        echo -e "${YELLOW}目录 $APP_DIR 已存在，跳过克隆${RESET}"
    else
        echo -e "${GREEN}正在克隆源码...${RESET}"
        git clone $REPO_URL
    fi
}

function install_dependencies() {
    echo -e "${YELLOW}检查 Node.js 是否安装...${RESET}"
    if ! command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}未检测到 Node.js，开始安装...${RESET}"
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
    else
        echo -e "${GREEN}Node.js 已安装: $(node -v)${RESET}"
    fi

    echo -e "${YELLOW}检查 pnpm 是否安装...${RESET}"
    if ! command -v pnpm >/dev/null 2>&1; then
        echo -e "${GREEN}未检测到 pnpm，开始安装...${RESET}"
        npm install -g pnpm
    else
        echo -e "${GREEN}pnpm 已安装: $(pnpm -v)${RESET}"
    fi

    echo -e "${GREEN}安装项目依赖...${RESET}"
    cd $APP_DIR || exit
    pnpm install
    cd ..
}

function build_project() {
    echo -e "${GREEN}编译项目...${RESET}"
    cd $APP_DIR || exit
    pnpm build
    cd ..
}

function check_mongo() {
    echo -e "${YELLOW}检测 MongoDB 服务...${RESET}"
    HOST=$(echo $MONGO_HOST | sed -E 's/mongodb:\/\/([^:/]+).*/\1/')
    PORT=$(echo $MONGO_HOST | sed -E 's/.*:([0-9]+).*/\1/')
    nc -z -w 3 $HOST $PORT
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}MongoDB 可用: $MONGO_HOST${RESET}"
        return 0
    else
        echo -e "${RED}无法连接 MongoDB: $MONGO_HOST${RESET}"
        return 1
    fi
}

function start_project() {
    check_mongo || { echo -e "${RED}请先确保 MongoDB 可用${RESET}"; return; }
    echo -e "${GREEN}启动项目...${RESET}"
    cd $APP_DIR || exit
    export MONGO_URL=$MONGO_HOST
    nohup pnpm start > app.log 2>&1 &
    cd ..
    echo -e "${YELLOW}项目已启动，日志输出到 $APP_DIR/app.log${RESET}"
}

function view_logs() {
    if [ -f "$APP_DIR/app.log" ]; then
        tail -f $APP_DIR/app.log
    else
        echo -e "${RED}日志文件不存在，请先启动项目${RESET}"
    fi
}

function stop_project() {
    echo -e "${YELLOW}停止项目...${RESET}"
    PID=$(pgrep -f "pnpm start")
    if [ "$PID" ]; then
        kill -9 $PID
        echo -e "${GREEN}项目已停止${RESET}"
    else
        echo -e "${RED}项目未运行${RESET}"
    fi
}

function install_mongo() {
    echo -e "${YELLOW}使用 Docker 安装 MongoDB...${RESET}"
    docker pull mongo:6
    docker run -d --name stb-mongo -p 27017:27017 mongo:6
    echo -e "${GREEN}MongoDB Docker 容器已启动，端口 27017${RESET}"
}

function uninstall_all() {
    echo -e "${YELLOW}停止项目...${RESET}"
    stop_project

    echo -e "${YELLOW}删除 STB 项目目录...${RESET}"
    rm -rf $APP_DIR
    echo -e "${GREEN}STB 项目目录已删除${RESET}"

    echo -e "${YELLOW}删除 MongoDB Docker 容器...${RESET}"
    if docker ps -a | grep stb-mongo >/dev/null; then
        docker stop stb-mongo
        docker rm stb-mongo
        echo -e "${GREEN}MongoDB Docker 容器已删除${RESET}"
    fi

    echo -e "${YELLOW}可选: 卸载 Node.js 和 pnpm? (y/N)${RESET}"
    read -p "请输入: " yn
    if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
        sudo apt purge -y nodejs
        sudo npm uninstall -g pnpm
        sudo apt autoremove -y
        echo -e "${GREEN}Node.js 和 pnpm 已卸载${RESET}"
    fi

    echo -e "${GREEN}卸载完成${RESET}"
}

function update_project() {
    echo -e "${YELLOW}停止项目以便更新...${RESET}"
    stop_project

    if [ -d "$APP_DIR" ]; then
        echo -e "${GREEN}进入项目目录更新源码...${RESET}"
        cd $APP_DIR || exit
        git fetch --all
        git reset --hard origin/main
        cd ..
    else
        echo -e "${RED}项目目录不存在，先下载源码${RESET}"
        clone_repo
    fi

    echo -e "${GREEN}更新依赖并编译...${RESET}"
    cd $APP_DIR || exit
    pnpm install
    pnpm build
    cd ..

    echo -e "${YELLOW}更新完成。是否立即启动项目? (y/N)${RESET}"
    read -p "请输入: " yn
    if [[ "$yn" == "y" || "$yn" == "Y" ]]; then
        start_project
    fi
}

# ================== 主循环 ==================
while true; do
    show_menu
    read -p "请输入选项: " choice
    case $choice in
        1) clone_repo ;;
        2) install_dependencies ;;
        3) build_project ;;
        4) start_project ;;
        5) view_logs ;;
        6) stop_project ;;
        7) check_mongo ;;
        8) install_mongo ;;
        9) uninstall_all ;;
        10) update_project ;;
        0) echo -e "${GREEN}退出脚本${RESET}"; exit 0 ;;
        *) echo -e "${RED}无效选项，请重新输入${RESET}" ;;
    esac
done
