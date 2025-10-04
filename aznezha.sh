#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== V1 哪吒监控管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装 哪吒v1${RESET}"
    echo -e "${GREEN}2) 安装 哪吒v1(Argo)${RESET}"
    echo -e "${GREEN}3) 管理 Agent${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装 哪吒 v1...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nezhadashboard.sh)
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装 哪吒 v1(Argo)...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nezhav1Argo.sh)
            pause
            ;;
        3)
            echo -e "${GREEN}管理 Agent...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/NezhaAgent.sh)
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
