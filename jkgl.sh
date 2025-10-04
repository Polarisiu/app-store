#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== 监控管理菜单 ===${RESET}"
    echo -e "${GREEN}1) V0 哪吒监控安装${RESET}"
    echo -e "${GREEN}2) V1 哪吒监控安装${RESET}"
    echo -e "${GREEN}3) Komari监控安装${RESET}"
    echo -e "${GREEN}4) 哪吒闭SSH${RESET}"
    echo -e "${GREEN}5) 哪吒Agent管理${RESET}"
    echo -e "${GREEN}6) KomariAgent管理${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装 V0 哪吒监控...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nezhav0Argo.sh)
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装 V1 哪吒监控...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/aznezha.sh)
            pause
            ;;
        3)
            echo -e "${GREEN}正在安装 Komari 监控...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/komarigl.sh)
            pause
            ;;
        4)
            echo -e "${GREEN} 哪吒闭SSH ...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/nezhassh.sh)
            pause
            ;;
        5)
            echo -e "${GREEN}正在安装哪吒 Agent管理...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/NezhaAgent.sh)
            pause
            ;;
        6)
            echo -e "${GREEN}正在安装 Komari Agent管理...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/KomariAgent.sh)
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
