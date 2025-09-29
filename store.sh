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

# ================== 首次运行自动保存 ==================
if [ ! -f "$SCRIPT_PATH" ]; then
    echo -e "${YELLOW}首次运行，正在保存脚本到 $SCRIPT_PATH ...${RESET}"
    curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL"
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}保存完成！${RESET}"

    # 首次提示快捷键
    echo -e "\n${YELLOW}💡 提示: 以后可以直接输入 ${RED}d${RESET}${YELLOW} 或 ${RED}D${RESET}${YELLOW} 命令来启动脚本${RESET}\n"
fi

# ================== 快捷命令 d/D ==================
for cmd in d D; do
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/$cmd"
done

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
declare -A apps
declare -A commands
# （保持你原来的 apps 和 commands 定义，这里不重复贴）

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
    for cmd in d D; do
        ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/$cmd"
    done
    echo -e "${GREEN}更新完成! 可直接使用 D/d 启动脚本${RESET}"
}

uninstall_script() {
    echo -e "${YELLOW}正在卸载脚本...${RESET}"
    rm -f "$SCRIPT_PATH"
    rm -f "$BIN_LINK_DIR/d" "$BIN_LINK_DIR/D"
    echo -e "${RED}卸载完成! ${RESET}"
    exit 0
}

# ================== 主循环 ==================
while true; do
    category_menu_handler
done
