#!/bin/bash

# ================== 颜色定义 ==================
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"
BOLD="\033[1m"

# ================== 脚本路径 ==================
SCRIPT_PATH="/root/store.sh"
SCRIPT_URL="https://raw.githubusercontent.com/Polarisiu/app-store/main/store.sh"
BIN_LINK_DIR="/usr/local/bin"

# ================== 首次运行自动安装 ==================
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${YELLOW}首次运行，正在保存脚本到 $SCRIPT_PATH ...${RESET}"
    curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 下载失败，请检查网络或 URL${RESET}"
        exit 1
    fi
    chmod +x "$SCRIPT_PATH"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/d"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/D"
    echo -e "${GREEN}✅ 安装完成${RESET}"
    echo -e "${GREEN}💡 快捷键已添加：d 或 D 可快速启动${RESET}"
fi

# ================== 一级菜单分类 ==================
declare -A categories=(
    [1]="Docker管理"
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
    [1,3]="Docker备份恢复"
    [1,4]="Docker容器迁移"
    [1,5]="NGINX反代"
    [1,6]="NginxProxyManager可视化面板"
    [2,1]="Wallos订阅"
    [2,2]="Vaultwarden (密码管理)"
    [2,3]="2FBA"
    [3,1]="Kuma-Mieru"
    [3,2]="Komari监控"
    [3,3]="哪吒监控"
    [3,4]="Akile Monitor"
    [3,5]="uptime-kuma"
    [3,6]="NodeSeeker监控"
    [4,1]="运维面板"
    [4,2]="XTrafficDash(流量监控)"
    [4,3]="Sun-Panel"
    [4,4]="WebSSH"
    [4,5]="NexusTerminal(SSH)"
    [4,6]="Sub-store"
    [4,7]="Poste.io邮局"
    [4,8]="oci-start"
    [4,9]="Y探长"
    [4,10]="OneNav书签管理"
    [4,11]="彩虹聚合DNS(MySQL)"
    [4,12]="ONE API"
    [4,13]="NEW API"
    [4,14]="青龙面板"
    [4,15]="Termix(SSH)"
    [4,16]="彩虹聚合DNS(远程MySQL)"
    [4,17]="VPS 剩余价值计算器"
    [5,1]="koodoreader阅读"
    [5,2]="LrcApi(歌词)"
    [5,3]="Openlist"
    [5,4]="SPlayer音乐"
    [5,5]="AutoBangumi"
    [5,6]="MoviePilot"
    [5,7]="qBittorrentv4.6.3"
    [5,8]="Vertex"
    [5,9]="yt-dlp视频下载工具"
    [5,10]="libretv"
    [5,11]="MoonTV"
    [5,12]="Emby(开心版)"
    [5,13]="Emby"
    [5,14]="Jellyfin"
    [5,15]="metatube"
    [5,16]="navidrome"
    [5,17]="music-tag-web"
    [5,18]="strm+302"
    [5,19]="弹幕API"
    [5,20]="music-player"
    [5,21]="磁力爬虫"
    [5,22]="qBittorrent(最新版)"
    [6,1]="Foxel图片管理"
    [6,2]="STB图床"
    [6,3]="兰空图床(MySQL)"
    [6,4]="兰空图床(远程MySQL)"
    [6,5]="图片API (兰空图床)"
    [6,6]="简单图床"
    [7,1]="ALLinSSL证书"
    [7,2]="SaveAnyBot(TG转存)"
    [7,3]="github镜像"
    [7,4]="Docker加速"
    [7,5]="计算圆周率"
    [7,6]="DockerGitHub加速代理"
    [7,7]="超级短链"
    [7,8]="多功能文件分享"
    [7,9]="订阅转换"
    [7,10]="笔记"
    [7,11]="TGBotRSS"
    [7,12]="TeleBox"
    [7,13]="随机头像生成"
    [7,14]="fastsend文件快传"
    [7,15]="FileTransferGo文件快传"
    [7,16]="send文件快传"
    [7,17]="pairdrop文件快传"
    [7,18]="TG转发机器人"
    [7,19]="Cloudreve网盘"
    [7,20]="firefox浏览器"
    [8,1]="异次元商城(MySQL)"
    [8,2]="异次元商城(远程MySQL)"
    [8,3]="萌次元商城"
    [8,4]="UPAYPRO"
)

# ================== 二级菜单命令 ==================
declare -A commands=(
    [1,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Docker.sh)'
    [1,2]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/msqldo.sh)'
    [1,3]='curl -fsSL https://raw.githubusercontent.com/xymn2023/DMR/main/docker_back.sh -o docker_back.sh && chmod +x docker_back.sh && ./docker_back.sh'
    [1,4]='curl -O https://raw.githubusercontent.com/woniu336/open_shell/main/Docker_container_migration.sh && chmod +x Docker_container_migration.sh && ./Docker_container_migration.sh'
    [1,5]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/tool/main/Nginxws.sh)'
    [1,6]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/nginx.sh)'
    [2,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/wallos.sh)'
    [2,2]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vaultwarden.sh)'
    [2,3]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/2fauth.sh)'
    [3,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/kuma-mieru.sh)'
    [3,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/komarigl.sh)'
    [3,3]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nezha.sh)'
    [3,4]='wget -O ak-setup.sh "https://raw.githubusercontent.com/akile-network/akile_monitor/refs/heads/main/ak-setup.sh" && chmod +x ak-setup.sh && sudo ./ak-setup.sh'
    [3,5]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/uptimek.sh)'
    [3,6]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/NodeSeeker.sh)'
    [4,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/panel/main/Panel.sh)'
    [4,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/xtrafficdash.sh)'
    [4,3]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/sun-panel.sh)'
    [4,4]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/webssh.sh)'
    [4,5]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/nexus-terminal.sh)'
    [4,6]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/sub-store.sh)'
    [4,7]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Poste.io.sh)'
    [4,8]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/oci-start.sh)'
    [4,9]='bash <(wget -qO- https://github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh)'
    [4,10]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/onenav.sh)'
    [4,11]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/dnss.sh)'
    [4,12]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/oneapi.sh)'
    [4,13]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/newapi.sh)'
    [4,14]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/qlmb.sh)'
    [4,15]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Termix.sh)'
    [4,16]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/DNSMgrwsq.sh)'
    [4,17]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vps-value.sh)'
    [5,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/koodoreader.sh)'
    [5,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/lacapi.sh)'
    [5,3]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Openlist.sh)'
    [5,4]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/splayer.sh)'
    [5,5]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Autobangumi.sh)'
    [5,6]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/movpv2.sh)'
    [5,7]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/qbittorrent.sh)'
    [5,8]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/vertex.sh)'
    [5,9]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ytdlb.sh)'
    [5,10]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/libretv.sh)'
    [5,11]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/mootv.sh)'
    [5,12]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/kxemby.sh)'
    [5,13]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/emby.sh)'
    [5,14]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Jellyfin.sh)'
    [5,15]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/metadata.sh)'
    [5,16]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/navidrome.sh)'
    [5,17]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/musictw.sh)'
    [5,18]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/qmediasync.sh)'
    [5,19]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/danmu.sh)'
    [5,20]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/mplayer.sh)'
    [5,21]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/sehuatang.sh)'
    [5,22]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/qBittorrentoo.sh)'
    [6,1]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/foxel.sh)'
    [6,2]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/stb.sh)'
    [6,3]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/lskyprodb.sh)'
    [6,4]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/lskypro.sh)'
    [6,5]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/apitu.sh)'
    [6,6]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/EasyImage.sh)'
    [7,1]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ALLSSL.sh)'
    [7,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/SaveAnyBot.sh)'
    [7,3]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/fdgit.sh)'
    [7,4]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/dockhub.sh)'
    [7,5]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/pai.sh)'
    [7,6]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/hubproxy.sh)'
    [7,7]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Zurl.sh)'
    [7,8]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Zdir.sh)'
    [7,9]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/subzh.sh)'
    [7,10]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Trilium.sh)'
    [7,11]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/TGBot.sh)'
    [7,12]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/TeleBox.sh)'
    [7,13]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/Colo.sh)'
    [7,14]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/FastSend.sh)'
    [7,15]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/FileTransfer.sh)'
    [7,16]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/send.sh)'
    [7,17]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/pairdrop.sh)'
    [7,18]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/TelegramBot.sh)'
    [7,19]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/Cloudreve.sh)'
    [7,20]='bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/app-store/main/firefox.sh)'
    [8,1]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ycyk.sh)'
    [8,2]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/ycywsq.sh)'
    [8,3]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/mcygl.sh)'
    [8,4]='bash <(curl -fsSL https://raw.githubusercontent.com/Polarisiu/app-store/main/UPayPro.sh)'
)

# ================== 菜单显示函数 ==================
show_category_menu() {
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}         应用分类菜单${RESET}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${RESET}\n"

    for i in $(seq 1 ${#categories[@]}); do
        printf "${GREEN}[%02d] %-20s${RESET}\n" "$i" "${categories[$i]}"
    done
    printf "${GREEN}[88] %-20s${RESET}\n" "更新脚本"
    printf "${GREEN}[99] %-20s${RESET}\n" "卸载脚本"
    printf "${GREEN}[0 ] %-20s${RESET}\n" "退出脚本"
}

show_app_menu() {
    local cat=$1
    echo -e "${GREEN}${BOLD}╔════════════════════════════════════════╗${RESET}"
    echo -e "${GREEN}${BOLD}        ${categories[$cat]}${RESET}"
    echo -e "${GREEN}${BOLD}╚════════════════════════════════════════╝${RESET}\n"

    local i=1
    declare -gA menu_map
    menu_map=()

    keys=()
    for key in "${!apps[@]}"; do
        if [[ $key == $cat,* ]]; then
            keys+=("$key")
        fi
    done

    IFS=$'\n' sorted_keys=($(sort -t, -k2n <<<"${keys[*]}"))
    unset IFS

    for key in "${sorted_keys[@]}"; do
        menu_map[$i]=$key
        printf "${GREEN}[%02d] %-25s${RESET}\n" "$i" "${apps[$key]}"
        ((i++))
    done

    printf "${GREEN}[0 ] %-25s${RESET}\n" "返回上一级"
}
# ================== 菜单处理函数 ==================
category_menu_handler() {
    while true; do
        show_category_menu
        read -rp "$(echo -e "${RED}请输入分类编号: ${RESET}")" cat_choice
        cat_choice=$(echo "$cat_choice" | xargs)

        if ! [[ "$cat_choice" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}无效选择，请输入数字!${RESET}"
            sleep 1
            continue
        fi

        case "$cat_choice" in
            0) echo -e "${RED}退出脚本！${RESET}"; exit 0 ;;
            88) update_script ;;
            99) uninstall_script ;;
            *) 
               if [[ -n "${categories[$cat_choice]}" ]]; then
                   app_menu_handler "$cat_choice"
               else
                   echo -e "${RED}无效选择，请重新输入!${RESET}"
                   sleep 1
               fi
            ;;
        esac
    done
}

app_menu_handler() {
    local cat=$1
    while true; do
        show_app_menu "$cat"
        read -rp "$(echo -e "${RED}请输入应用编号: ${RESET}")" app_choice
        app_choice=$(echo "$app_choice" | xargs)

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

        read -rp $'\n\033[33m按回车返回应用菜单...\033[0m'
    done
}

# ================== 脚本更新与卸载 ==================
update_script() {
    echo -e "${YELLOW}正在更新脚本...${RESET}"
    curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL"
    chmod +x "$SCRIPT_PATH"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/d"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/D"
    echo -e "${GREEN}更新完成! 可直接使用 D/d 启动脚本${RESET}"
}

uninstall_script() {
    echo -e "${YELLOW}正在卸载脚本...${RESET}"
    rm -f "$SCRIPT_PATH"
    rm -f "$BIN_LINK_DIR/d" "$BIN_LINK_DIR/D"
    echo -e "${RED}卸载完成!${RESET}"
    exit 0
}

# ================== 主循环 ==================
while true; do
    category_menu_handler
done
