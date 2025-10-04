#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== 监控管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装 unzip${RESET}"
    echo -e "${GREEN}2) V0 哪吒监控安装${RESET}"
    echo -e "${GREEN}3) V1 哪吒监控安装${RESET}"
    echo -e "${GREEN}4) Komari 监控安装${RESET}"
    echo -e "${GREEN}5) V0 关闭 SSH 功能${RESET}"
    echo -e "${GREEN}6) V1 关闭 SSH 功能${RESET}"
    echo -e "${GREEN}7) 哪吒Agent管理${RESET}"
    echo -e "${GREEN}8) KomariAgent管理${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装 unzip...${RESET}"
            apt update && apt install unzip -y
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装 V0 哪吒监控...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nezhav0Argo.sh)
            pause
            ;;
        3)
            echo -e "${GREEN}正在安装 V1 哪吒监控...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/aznezha.sh)
            pause
            ;;
        4)
            echo -e "${GREEN}正在安装 Komari 监控...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/komarigl.sh)
            pause
            ;;
        5)
            echo -e "${GREEN}正在关闭 V0 SSH 功能...${RESET}"
            sed -i 's|^ExecStart=.*|& --disable-command-execute --disable-auto-update --disable-force-update|' /etc/systemd/system/nezha-agent.service
            systemctl daemon-reload
            systemctl restart nezha-agent
            pause
            ;;
        6)
            echo -e "${GREEN}正在关闭 V1 SSH 功能...${RESET}"
            sed -i 's/disable_command_execute: false/disable_command_execute: true/' /opt/nezha/agent/config.yml
            systemctl restart nezha-agent
            pause
            ;;
        7)
            echo -e "${GREEN}正在安装哪吒 Agent管理...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/NezhaAgent.sh)
            pause
            ;;
        8)
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
