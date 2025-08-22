#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"
BOLD="\033[1m"

# 脚本固定路径
SCRIPT_PATH="$HOME/store.sh"
VERSION="1.0.3"

# ================== 一级菜单分类 ==================
declare -A categories
categories=(
    [1]="Docker及数据库"
    [2]="订阅服务"
    [3]="监控通知"
    [4]="管理面板"
    [5]="多媒体工具"
    [6]="图床工具"
    [7]="实用工具"
)

# ================== 二级菜单应用 ==================
declare -A apps
apps=(
    [1,1]="安装/管理 Docker"
    [1,2]="MySQL数据管理"

    [2,1]="Wallos订阅"
    [2,2]="Vaultwarden (密码管理)"

    [3,1]="Kuma-Mieru"

    [4,1]="彩虹聚合DNS"
    [4,2]="XTrafficDash(流量监控)"
    [4,3]="Sun-Panel"
    [4,4]="WebSSH"
    [4,5]="NexusTerminal(SSH)"
    [4,6]="Sub-store"
    [4,7]="Poste.io邮局"
    [4,8]="oci-start"
    [4,9]="Y探长"
    [4,10]="R探长"

    [5,1]="音乐服务（三合一）"
    [5,2]="LrcApi(歌词)"
    [5,3]="Openlist"
    [5,4]="SPlayer音乐"
    [5,5]="AutoBangumi"
    [5,6]="MoviePilot"
    [5,7]="qBittorrentv4.6.3"
    [5,8]="Vertex"
    [5,9]="yt-dlp视频下载工具"

    [6,1]="Foxel图片管理"
    [6,2]="STB图床"
    [6,3]="兰空图床(无MySQL)"
    [6,4]="兰空图床(有MySQL)"
    [6,5]="图片API (兰空图床)"
    [6,6]="简单图床"

    [7,1]="ALLinSSL证书"
)

# ================== 二级菜单命令 ==================
declare -A commands
commands=(
    [1,1]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh | bash"'
    [1,2]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/mysql.sh | bash"'

    [2,1]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/wallos.sh | bash"'
    [2,2]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vaultwarden.sh | bash"'

    [3,1]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/kuma-mieru.sh | bash"'

    [4,1]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/dnss.sh | bash"'
    [4,2]='bash -c "curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/xtrafficdash.sh | bash"'
    [4,3]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/sun-panel.sh | bash"'
    [4,4]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/webssh.sh | bash"'
    [4,5]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nexus-terminal.sh | bash"'
    [4,6]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/sub-store.sh | bash"'
    [4,7]='bash -c "curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh"'
    [4,8]='bash -c "curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/oci-start.sh | bash"'
    [4,9]='bash -c "curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/Yoci-helper.sh | bash"'
    [4,10]='bash -c "curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/R-Bot.sh | bash"'

    [5,1]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/music_full_auto.sh | bash"'
    [5,2]='bash -c "curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/lacapi.sh | bash"'
    [5,3]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Openlist.sh | bash"'
    [5,4]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/splayer.sh | bash"'
    [5,5]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Autobangumi.sh | bash"'
    [5,6]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/moviepilot.sh | bash"'
    [5,7]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/qbittorrent.sh | bash"'
    [5,8]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vertex.sh | bash"'
    [5,9]='bash -c "curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ytdlb.sh | bash"'

    [6,1]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/foxel.sh | bash"'
    [6,2]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/stb.sh | bash"'
    [6,3]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/lsky_menu.sh | bash"'
    [6,4]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Lsky.sh | bash"'
    [6,5]='bash -c "curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/apitu.sh | bash"'
    [6,6]='bash -c "curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/EasyImage.sh | bash"'

    [7,1]='bash -c "curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ALLSSL.sh | bash"'
)

# ================== 菜单显示函数 ==================
show_category_menu() {
    clear
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}         应用分类菜单${RESET}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${RESET}\n"

    for i in $(seq 1 ${#categories[@]}); do
        echo -e "${GREEN}[$i] ${categories[$i]}${RESET}"
    done
    echo -e "${GREEN}[88] 更新脚本${RESET}"
    echo -e "${GREEN}[99] 卸载脚本${RESET}"
    echo -e "${GREEN}[0]  退出脚本${RESET}"
}

show_app_menu() {
    local cat=$1
    clear
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}        ${categories[$cat]}${RESET}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${RESET}\n"

    # 二级菜单自动编号
    local i=1
    declare -A menu_map
    for key in "${!apps[@]}"; do
        if [[ $key == $cat,* ]]; then
            menu_map[$i]=$key
            echo -e "${GREEN}[$i] ${apps[$key]}${RESET}"
            ((i++))
        fi
    done

    echo -e "${GREEN}[0] 返回上一级${RESET}"

    # 返回映射数组供选择使用
    echo "${menu_map[@]}"
}

# ================== 菜单处理函数 ==================
category_menu_handler() {
    while true; do
        show_category_menu
        read -p $'\033[31m请输入分类编号: \033[0m' cat_choice
        cat_choice=$(echo "$cat_choice" | xargs)
        if [[ "$cat_choice" == "0" ]]; then
            echo -e "${RED}退出脚本，感谢使用！${RESET}"
            exit 0
        elif [[ "$cat_choice" == "88" ]]; then
            update_script
        elif [[ "$cat_choice" == "99" ]]; then
            uninstall_script
        elif [[ -n "${categories[$cat_choice]}" ]]; then
            app_menu_handler "$cat_choice"
        else
            echo -e "${RED}无效选择，请重新输入!${RESET}"
            sleep 1
        fi
    done
}

app_menu_handler() {
    local cat=$1
    while true; do
        # 获取菜单映射
        map=($(show_app_menu "$cat"))
        read -p $'\033[31m请输入应用编号: \033[0m' app_choice
        app_choice=$(echo "$app_choice" | xargs)

        if [[ "$app_choice" == "0" ]]; then
            break
        elif [[ "$app_choice" == "88" ]]; then
            update_script
        elif [[ "$app_choice" == "99" ]]; then
            uninstall_script
        elif [[ -n "${map[$app_choice-1]}" ]]; then
            key="${map[$app_choice-1]}"
            bash -c "${commands[$key]}"
        else
            echo -e "${RED}无效选择，请重新输入!${RESET}"
        fi
        read -p $'\n\033[33m按 Enter 返回应用菜单...\033[0m'
    done
}

# ================== 脚本更新与卸载 ==================
update_script() {
    echo -e "${YELLOW}正在更新脚本...${RESET}"
    cp "$SCRIPT_PATH" "$SCRIPT_PATH.bak"
    curl -fsSL -o "$SCRIPT_PATH" https://raw.githubusercontent.com/Polarisiu/app-store/main/store.sh
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}更新完成! 已备份原脚本为 vpsdocker.sh.bak${RESET}"
}

uninstall_script() {
    rm -f "$SCRIPT_PATH"
    echo -e "${RED}卸载完成!${RESET}"
    exit 0
}

# ================== 主循环 ==================
while true; do
    category_menu_handler
done
