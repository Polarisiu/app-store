#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"
BOLD="\033[1m"

# 脚本固定路径
SCRIPT_PATH="$HOME/store.sh"
VERSION="1.0.4"

# ================== 一级菜单分类 ==================
declare -A categories=(
    [1]="Docker及数据库"
    [2]="订阅服务"
    [3]="监控通知"
    [4]="管理面板"
    [5]="多媒体工具"
    [6]="图床工具"
    [7]="实用工具"
    [8]="交易商店"
)

# ================== 二级菜单应用 ==================
declare -A apps=(
    [1,1]="安装/管理 Docker"
    [1,2]="MySQL数据管理"

    [2,1]="Wallos订阅"
    [2,2]="Vaultwarden (密码管理)"

    [3,1]="Kuma-Mieru"
    [3,2]="Komari监控"

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
    [7,2]="SaveAnyBot(TG转存)"
    [7,3]="github镜像"

    [8,1]="异次元商城"
    [8,2]="萌次元商城"
    [8,3]="BEpusdt收款"
)

# ================== 二级菜单命令 ==================
declare -A commands=(
    [1,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh)'
    [1,2]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/mysql.sh)'

    [2,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/wallos.sh)'
    [2,2]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vaultwarden.sh)'

    [3,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/kuma-mieru.sh)'
    [3,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/komarigl.sh)'

    [4,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/dnss.sh)'
    [4,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/xtrafficdash.sh)'
    [4,3]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/sun-panel.sh)'
    [4,4]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/webssh.sh)'
    [4,5]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nexus-terminal.sh)'
    [4,6]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/sub-store.sh)'
    [4,7]='curl -sS -O https://raw.githubusercontent.com/woniu336/open_shell/main/poste_io.sh && chmod +x poste_io.sh && ./poste_io.sh'
    [4,8]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/oci-start.sh)'
    [4,9]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/Yoci-helper.sh)'
    [4,10]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/oracle/main/R-Bot.sh)'

    [5,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/music_full_auto.sh)'
    [5,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/lacapi.sh)'
    [5,3]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Openlist.sh)'
    [5,4]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/splayer.sh)'
    [5,5]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Autobangumi.sh)'
    [5,6]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/moviepilot.sh)'
    [5,7]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/qbittorrent.sh)'
    [5,8]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vertex.sh)'
    [5,9]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ytdlb.sh)'

    [6,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/foxel.sh)'
    [6,2]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/stb.sh)'
    [6,3]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/lsky_menu.sh)'
    [6,4]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Lsky.sh)'
    [6,5]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/apitu.sh)'
    [6,6]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/EasyImage.sh)'

    [7,1]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ALLSSL.sh)'
    [7,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/SaveAnyBot.sh)'
    [7,3]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/fdgit.sh)'

    [8,1]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ycyk.sh)'
    [8,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/mcygl.sh)'
    [8,3]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/BEpusdt.sh)'
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
    echo -e "${GREEN}[0] 退出脚本${RESET}"
}

show_app_menu() {
    local cat=$1
    clear
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}        ${categories[$cat]}${RESET}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${RESET}\n"

    local i=1
    declare -gA menu_map
    menu_map=()

    # 遍历当前分类下的应用
    keys=()
    for key in "${!apps[@]}"; do
        if [[ $key == $cat,* ]]; then
            keys+=("$key")
        fi
    done

    # 排序 keys
    IFS=$'\n' sorted_keys=($(sort -t, -k2n <<<"${keys[*]}"))
    unset IFS

    for key in "${sorted_keys[@]}"; do
        menu_map[$i]=$key
        echo -e "${GREEN}[$i] ${apps[$key]}${RESET}"
        ((i++))
    done

    echo -e "${GREEN}[0] 返回上一级${RESET}"
}

# ================== 菜单处理函数 ==================
category_menu_handler() {
    while true; do
        show_category_menu
        read -rp "$(echo -e "${RED}请输入分类编号: ${RESET}")" cat_choice
        cat_choice=$(echo "$cat_choice" | xargs)

        # 输入校验
        if ! [[ "$cat_choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}无效选择，请输入数字!${RESET}"
            sleep 1
            continue
        fi

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
        show_app_menu "$cat"
        read -rp "$(echo -e "${RED}请输入应用编号: ${RESET}")" app_choice
        app_choice=$(echo "$app_choice" | xargs)

        # 检查是否为数字
        if ! [[ "$app_choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}无效选择，请输入数字!${RESET}"
            sleep 1
            continue
        fi

        if [[ "$app_choice" == "0" ]]; then
            break
        elif [[ -n "${menu_map[$app_choice]}" ]]; then
            key="${menu_map[$app_choice]}"
            bash -c "${commands[$key]}"
        else
            echo -e "${RED}无效选择，请重新输入!${RESET}"
            sleep 1
        fi

        read -rp $'\n\033[33m按 Enter 返回应用菜单...\033[0m'
    done
}

# ================== 脚本更新与卸载 ==================
update_script() {
    echo -e "${YELLOW}正在更新脚本...${RESET}"
    curl -fsSL -o "$SCRIPT_PATH" https://raw.githubusercontent.com/Polarisiu/app-store/main/store.sh
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}更新完成!${RESET}"
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
