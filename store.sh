#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"
BOLD="\033[1m"

# 脚本固定路径
SCRIPT_PATH="$HOME/vpsdocker.sh"
VERSION="1.0.3"

# ================== 菜单项定义 ==================
MENU_ITEMS=(
    "安装/管理 Docker"
    "MySQL数据管理"
    "Wallos订阅"
    "Kuma-Mieru"
    "彩虹聚合DNS"
    "XTrafficDash"
    "NexusTerminal"
    "VPS价值计算"
    "密码管理 (Vaultwarden)"
    "Sun-Panel"
    "SPlayer音乐"
    "Vertex"
    "AutoBangumi"
    "MoviePilot"
    "Foxel"
    "STB图床"
    "oci-start"
    "Y探长"
    "Sub-store"
    "Poste.io邮局"
    "WebSSH"
    "Openlist"
    "qBittorrent v4.6.3"
    "音乐服务"
    "兰空图床(无MySQL)"
    "兰空图床(有MySQL)"
    "简单图床"
    "yt-dlp视频下载工具"
    "LrcApi"
    "图片API (兰空图床)"
    "更新菜单脚本"
    "卸载菜单脚本"
    "退出"
)

# ================== 菜单显示函数 ==================
show_menu() {
    clear
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}          Docker 应用管理菜单${RESET}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${RESET}\n"

    local total=${#MENU_ITEMS[@]}
    local half=$(( (total + 1) / 2 ))

    for ((i=0; i<half; i++)); do
        left_index=$((i+1))
        right_index=$((i+half))
        left_item="${MENU_ITEMS[$i]}"
        right_item=""
        if [ $right_index -lt $total ]; then
            right_item="${MENU_ITEMS[$right_index]}"
        fi
        printf "${GREEN}[%02d] %-22s${RESET}" "$left_index" "$left_item"
        if [ -n "$right_item" ]; then
            printf " ${GREEN}[%02d] %-22s${RESET}" "$((right_index+1))" "$right_item"
        fi
        echo
    done
    echo
}

# ================== 功能执行函数 ==================
install_service() {
    case "$1" in
        1|01) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh) ;;
        2|02) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/mysql.sh) ;;
        3|03) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/wallos.sh) ;;
        4|04) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/kuma-mieru.sh) ;;
        5|05) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/dnss.sh) ;;
        6|06) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/xtrafficdash.sh) ;;
        7|07) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nexus-terminal.sh) ;;
        8|08) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vps-value.sh) ;;
        9|09) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vaultwarden.sh) ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/sun-panel.sh) ;;
        11) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/splayer.sh) ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vertex.sh) ;;
        13) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Autobangumi.sh) ;;
        14) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/moviepilot.sh) ;;
        15) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/foxel.sh) ;;
        16) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/stb.sh) ;;
        17) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/oci-start.sh) ;;
        18) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/Yoci-helper.sh) ;;
        19) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/sub-store.sh) ;;
        20) curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh ;;
        21) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/webssh.sh) ;;
        22) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Openlist.sh) ;;
        23) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/qbittorrent.sh) ;;
        24) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/music_full_auto.sh) ;;
        25) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/lsky_menu.sh) ;;
        26) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Lsky.sh) ;;
        27) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/EasyImage.sh) ;;
        28) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ytdlb.sh) ;;
        29) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/lacapi.sh) ;;
        30) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/apitu.sh) ;;
        31|88) # 更新菜单
            echo -e "${RED}正在更新脚本...${RESET}"
            curl -fsSL -o "$SCRIPT_PATH" https://raw.githubusercontent.com/Polarisiu/app-store/main/store.sh
            chmod +x "$SCRIPT_PATH"
            echo -e "${RED}更新完成!${RESET}"
            ;;
        32|99) # 卸载脚本
            echo -e "${RED}正在卸载脚本...${RESET}"
            rm -f "$SCRIPT_PATH"
            echo -e "${RED}卸载完成!${RESET}"
            exit 0
            ;;
        33|0)  # 退出
            echo -e "${RED}退出脚本，感谢使用！${RESET}"
            sleep 1
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入!${RESET}"
            ;;
    esac
}

# ================== 主循环 ==================
while true; do
    show_menu
    read -p $'\033[31m请输入编号: \033[0m' choice
    choice=$(echo "$choice" | xargs)  # 去掉前后空格
    install_service "$choice"
    echo -e "\n\033[31m按 Enter 返回菜单...\033[0m"
    read
done
