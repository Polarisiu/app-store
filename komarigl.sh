#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== Komari 监控管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装 Komari${RESET}"
    echo -e "${GREEN}2) 安装 NGINX反代${RESET}"
    echo -e "${GREEN}3) 卸载 Komari Agent${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    echo
    read -p $'\033[32m请选择操作 (0-2): \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装 Komari...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/komari.sh)
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装 NGINX反代...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/nigxssl.sh)
            pause
            ;;
        3)
            echo -e "${GREEN}正在卸载 Komari Agent...${RESET}"
            sudo systemctl stop komari-agent
            sudo systemctl disable komari-agent
            sudo rm -f /etc/systemd/system/komari-agent.service
            sudo systemctl daemon-reload
            sudo rm -rf /opt/komari /var/log/komari
            echo -e "${GREEN}卸载完成！${RESET}"
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
