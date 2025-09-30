#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== V1 哪吒监控管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装 unzip${RESET}"
    echo -e "${GREEN}2) 安装 Docker + Docker Compose${RESET}"
    echo -e "${GREEN}3) 运行 Nginx 反代${RESET}"
    echo -e "${GREEN}4) 运行 Nginx 反代(CFCDN)${RESET}"
    echo -e "${GREEN}5) 安装 哪吒 v1${RESET}"
    echo -e "${GREEN}6) 安装 哪吒 v1(国内)${RESET}"
    echo -e "${GREEN}7) 卸载 Agent${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装 unzip...${RESET}"
            apt update && apt install unzip -y
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装 Docker + Docker Compose...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh)
            pause
            ;;
        3)
            echo -e "${GREEN}正在运行 Nginx 反代...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/Nginxws.sh)
            pause
            ;;
        4)
            echo -e "${GREEN}正在运行 Nginx 反代(CFCDN)...${RESET}"
            wget -O 1keji_nginxfdnz06.sh "https://pan.1keji.net/f/P9u3/1keji_nginxfdnz06.sh" && chmod +x 1keji_nginxfdnz06.sh && ./1keji_nginxfdnz06.sh
            pause
            ;;
        5)
            echo -e "${GREEN}正在安装 哪吒 v1...${RESET}"
            curl -L https://raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
            pause
            ;;
        6)
            echo -e "${GREEN}正在安装 哪吒 v1(国内)...${RESET}"
            curl -L https://gitee.com/naibahq/scripts/raw/main/install.sh -o nezha.sh && chmod +x nezha.sh && sudo CN=true ./nezha.sh
            pause
            ;;
        7)
            echo -e "${GREEN}正在卸载 Agent...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nzagent.sh)
            pause
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入${RESET}"
            sleep 1
            menu
            ;;
    esac
}

pause() {
    read -p $'\033[32m按回车键返回菜单...\033[0m'
    menu
}

menu
