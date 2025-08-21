#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"
BOLD="\033[1m"

# 脚本固定路径
SCRIPT_PATH="$HOME/vpsdocker.sh"
VERSION="1.0.2"

# ================== 菜单函数 ==================
show_menu() {
    clear
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}          Docker 应用管理菜单${RESET}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${RESET}\n"
    echo -e "${GREEN}[01] 安装/管理 Docker${RESET}"
    echo -e "${GREEN}[02] MySQL数据管理${RESET}"
    echo -e "${GREEN}[03] Wallos订阅${RESET}"
    echo -e "${GREEN}[04] Kuma-Mieru${RESET}"
    echo -e "${GREEN}[05] 彩虹聚合DNS${RESET}"
    echo -e "${GREEN}[06] XTrafficDash${RESET}"
    echo -e "${GREEN}[07] NexusTerminal${RESET}"
    echo -e "${GREEN}[08] VPS价值计算${RESET}"
    echo -e "${GREEN}[09] 密码管理 (Vaultwarden)${RESET}"
    echo -e "${GREEN}[10] Sun-Panel${RESET}"
    echo -e "${GREEN}[11] SPlayer音乐${RESET}"
    echo -e "${GREEN}[12] Vertex${RESET}"
    echo -e "${GREEN}[13] AutoBangumi${RESET}"
    echo -e "${GREEN}[14] MoviePilot${RESET}"
    echo -e "${GREEN}[15] Foxel${RESET}"
    echo -e "${GREEN}[16] STB图床${RESET}"
    echo -e "${GREEN}[17] oci-start${RESET}"
    echo -e "${GREEN}[18] Y探长${RESET}"
    echo -e "${GREEN}[19] Sub-store${RESET}"
    echo -e "${GREEN}[20] Poste.io邮局${RESET}"
    echo -e "${GREEN}[21] WebSSH${RESET}"
    echo -e "${GREEN}[22] Openlist${RESET}"
    echo -e "${GREEN}[23] qBittorrentv4.6.3${RESET}"
    echo -e "${GREEN}[24] 音乐服务${RESET}"
    echo -e "${GREEN}[25] 兰空图床(无MySQL)${RESET}"
    echo -e "${GREEN}[26] 兰空图床(有MySQL)${RESET}"
    echo -e "${GREEN}[27] 简单图床${RESET}"
    echo -e "${GREEN}[28] yt-dlp视频下载工具${RESET}"
    echo -e "${GREEN}[88] 更新菜单脚本${RESET}"
    echo -e "${GREEN}[99] 卸载菜单脚本${RESET}"
    echo -e "${GREEN}[0]  退出${RESET}"
}

# ================== 功能函数 ==================
install_service() {
    case "$1" in
        1|01) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh) ;;
        2|02) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/mysql.sh) ;;
        3|03) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/wallos.sh) ;;
        4|04) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/kuma-mieru.sh) ;;
        5|05) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/dnss.sh) ;;
        6|06) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/xtrafficdash.sh) ;;
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
        19) bash <(curl -sL https://raw.githubusercontent.com//Polarisiu/app-store/main/sub-store.sh) ;;
        20) curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh ;;
        21) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/webssh.sh) ;;
        22) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Openlist.sh) ;;
        23) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/qbittorrent.sh) ;;
        24) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/music_full_auto.sh) ;;
        25) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/lsky_menu.sh) ;;
        26) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Lsky.sh) ;;
        27) bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/EasyImage.sh) ;;
        28) bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ytdlb.sh) ;;
        88)
            echo -e "\033[31m正在更新脚本...\033[0m"
            curl -fsSL -o "$SCRIPT_PATH" https://raw.githubusercontent.com/Polarisiu/app-store/main/store.sh
            chmod +x "$SCRIPT_PATH"
            echo -e "\033[31m更新完成!\033[0m"
            ;;
        99)
            echo -e "\033[31m正在卸载脚本...\033[0m"
            rm -f "$SCRIPT_PATH"
            echo -e "\033[31m卸载完成!\033[0m"
            exit 0
            ;;
        0)
            echo -e "\033[31m退出脚本，感谢使用！\033[0m"
            sleep 1
            exit 0
            ;;
        *)
            echo -e "\033[31m无效选择，请重新输入!\033[0m"
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
