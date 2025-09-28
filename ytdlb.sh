#!/bin/bash
# ============================================
# 一键安装/运行 yt-dlp 视频下载工具
# 菜单字体全绿色
# 支持中文、空格目录
# 安装需手动按菜单 1
# ============================================

# 配色
gl_lv="\033[32m"  # 绿色
gl_bai="\033[0m"  # 重置

# 通用选项
COMMON_OPTS="--write-subs --sub-langs all --write-thumbnail --embed-thumbnail --write-info-json --no-overwrites --no-post-overwrites"

# 目录与文件（统一放到 /opt/yt-dlp）
APP_NAME="yt-dlp"
VIDEO_DIR="/opt/$APP_NAME/videos"
APP_DIR="/opt/$APP_NAME"
URL_FILE="$APP_DIR/urls.txt"
ARCHIVE_FILE="$APP_DIR/archive.txt"
APP_ID="66"

mkdir -p "$VIDEO_DIR"
mkdir -p /opt/docker && touch /opt/docker/appno.txt

# 安装依赖函数
install_dep() {
    if ! command -v "$1" &>/dev/null; then
        echo -e "${gl_lv}安装依赖: $1 ...${gl_bai}"
        sudo apt update -y
        sudo apt install -y "$1"
    fi
}

# 添加应用 ID
add_app_id() {
    if ! grep -q "\b$APP_ID\b" /opt/docker/appno.txt; then
        echo "$APP_ID" >> /opt/docker/appno.txt
    fi
}

# 显示状态
send_stats() {
    echo -e "\n${gl_lv}=== $1 ===${gl_bai}"
}

# 安装 yt-dlp
install_ytdlp() {
    send_stats "安装 yt-dlp..."
    install_dep ffmpeg
    sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
    sudo chmod a+rx /usr/local/bin/yt-dlp
    add_app_id
    echo -e "${gl_lv}安装完成${gl_bai}"
}

# 更新 yt-dlp
update_ytdlp() {
    send_stats "更新 yt-dlp..."
    sudo yt-dlp -U
    add_app_id
    echo -e "${gl_lv}更新完成${gl_bai}"
}

# 主菜单函数
yt_menu_pro() {
    while true; do
        # 状态
        if [ -x "/usr/local/bin/yt-dlp" ]; then
            YTDLP_STATUS="已安装"
        else
            YTDLP_STATUS="未安装"
        fi

        clear
        echo -e "${gl_lv}=== yt-dlp 下载工具 ===${gl_bai}"
        echo -e "${gl_lv}yt-dlp 状态: $YTDLP_STATUS${gl_bai}"
        echo -e "${gl_lv}视频保存目录: $VIDEO_DIR${gl_bai}"
        echo -e "${gl_lv}支持 YouTube、Bilibili、Twitter 等站点${gl_bai}"
        echo -e "${gl_lv}官网: https://github.com/yt-dlp/yt-dlp${gl_bai}"
        echo -e "${gl_lv}-------------------------${gl_bai}"
        echo -e "${gl_lv}已下载视频列表（按大小排序，输入序号删除）:${gl_bai}"

        # 视频列表（支持中文空格目录）
        dirs=()
        index=0
        if [ "$(ls -A "$VIDEO_DIR" 2>/dev/null)" ]; then
            mapfile -t temp_dirs < <(find "$VIDEO_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
            declare -A dir_sizes
            for dir in "${temp_dirs[@]}"; do
                size=$(du -s "$dir" 2>/dev/null | cut -f1)  # KB
                dir_sizes["$dir"]=$size
            done
            sorted_dirs=($(for d in "${!dir_sizes[@]}"; do echo -e "${dir_sizes[$d]}\t$d"; done | sort -nr | awk '{print $2}'))
            for dir in "${sorted_dirs[@]}"; do
                size_human=$(du -sh "$dir" 2>/dev/null | cut -f1)
                if [ -d "$dir" ]; then
                    mtime=$(stat -c "%y" "$dir" 2>/dev/null | cut -d'.' -f1)
                else
                    mtime="未知"
                fi
                name=$(basename "$dir")
                echo -e "${gl_lv}  [$index] $name - $size_human - 最近修改: $mtime${gl_bai}"
                dirs[$index]="$dir"
                ((index++))
            done
        else
            echo -e "${gl_lv}  （暂无）${gl_bai}"
        fi

        echo -e "${gl_lv}-------------------------${gl_bai}"
        echo -e "${gl_lv}1. 安装 yt-dlp   2. 更新 yt-dlp   3. 卸载 yt-dlp${gl_bai}"
        echo -e "${gl_lv}5. 单个视频下载  6. 批量视频下载  7. 自定义参数下载${gl_bai}"
        echo -e "${gl_lv}8. 下载为MP3音频 9. 删除视频目录${gl_bai}"
        echo -e "${gl_lv}0. 退出${gl_bai}"
        echo -e "${gl_lv}-------------------------${gl_bai}"

        read -e -p "$(echo -e ${gl_lv}请输入选项编号: ${gl_bai})" choice

        case $choice in
            1) install_ytdlp; read -n1 -r -p "按任意键继续..." ;;
            2) update_ytdlp; read -n1 -r -p "按任意键继续..." ;;
            3)
                send_stats "卸载 yt-dlp..."
                sudo rm -f /usr/local/bin/yt-dlp
                sed -i "/\b$APP_ID\b/d" /opt/docker/appno.txt
                echo -e "${gl_lv}已卸载${gl_bai}"
                read -n1 -r -p "按任意键继续..." ;;
            5)
                read -e -p "请输入视频链接: " url
                yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" $COMMON_OPTS -o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" "$url"
                read -n1 -r -p "下载完成，按任意键继续..." ;;
            6)
                install_dep nano
                if [ ! -f "$URL_FILE" ]; then
                    echo -e "# 每行输入一个视频链接\n# 示例：https://www.bilibili.com/bangumi/play/ep733316" > "$URL_FILE"
                fi
                nano "$URL_FILE"
                yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" $COMMON_OPTS -a "$URL_FILE" -o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s"
                read -n1 -r -p "批量下载完成，按任意键继续..." ;;
            7)
                read -e -p "请输入完整 yt-dlp 参数（不含 yt-dlp）: " custom
                yt-dlp -P "$VIDEO_DIR" $custom $COMMON_OPTS -o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s"
                read -n1 -r -p "执行完成，按任意键继续..." ;;
            8)
                read -e -p "请输入视频链接: " url
                yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 $COMMON_OPTS -o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" "$url"
                read -n1 -r -p "音频下载完成，按任意键继续..." ;;
            9)
                if [ ${#dirs[@]} -eq 0 ]; then
                    echo -e "${gl_lv}没有视频目录可删除${gl_bai}"
                    read -n1 -r -p "按任意键继续..."
                    continue
                fi
                read -e -p "请输入要删除的视频序号: " idx
                if [[ "$idx" =~ ^[0-9]+$ ]] && [ "$idx" -ge 0 ] && [ "$idx" -lt "${#dirs[@]}" ]; then
                    sudo rm -rf "${dirs[$idx]}"
                    echo -e "${gl_lv}目录已删除：$(basename "${dirs[$idx]}")${gl_bai}"
                else
                    echo -e "${gl_lv}无效序号${gl_bai}"
                fi
                read -n1 -r -p "按任意键继续..." ;;
            0) break ;;
            *) echo -e "${gl_lv}无效选项${gl_bai}"; read -n1 -r -p "按任意键继续..." ;;
        esac
    done
}

# 运行菜单
yt_menu_pro
