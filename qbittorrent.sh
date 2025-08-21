#!/bin/bash
# ========================================
# qBittorrent-Nox 一键管理脚本
# ========================================

# 颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

SERVICE_NAME="qbittorrent"

# 部署 qBittorrent-Nox
install_qbittorrent() {
    echo -e "${YELLOW}更新软件包列表...${RESET}"
    sudo apt update
    echo -e "${YELLOW}安装 qBittorrent-Nox...${RESET}"
    sudo apt install -y qbittorrent-nox

    echo -e "${YELLOW}创建 systemd 服务文件...${RESET}"
    sudo tee /etc/systemd/system/qbittorrent.service > /dev/null <<EOF
[Unit]
Description=qBittorrent Command Line Client
After=network.target

[Service]
ExecStart=/usr/bin/qbittorrent-nox --webui-port=8080
User=root
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl start qbittorrent
    sudo systemctl enable qbittorrent

    echo -e "${GREEN}qBittorrent-Nox 安装完成并已启动!${RESET}"
    echo -e "${CYAN}WebUI 访问地址: http://$(hostname -I | awk '{print $1}'):8080${RESET}"
    echo -e "${YELLOW}默认用户名: admin, 默认密码: adminadmin${RESET}"
}

# 启动服务
start_qbittorrent() {
    sudo systemctl start ${SERVICE_NAME}
    echo -e "${GREEN}qBittorrent 已启动${RESET}"
}

# 停止服务
stop_qbittorrent() {
    sudo systemctl stop ${SERVICE_NAME}
    echo -e "${YELLOW}qBittorrent 已停止${RESET}"
}

# 重启服务
restart_qbittorrent() {
    sudo systemctl restart ${SERVICE_NAME}
    echo -e "${GREEN}qBittorrent 已重启${RESET}"
}

# 查看日志
logs_qbittorrent() {
    sudo journalctl -u ${SERVICE_NAME} -f
}

# 卸载服务
uninstall_qbittorrent() {
    sudo systemctl stop ${SERVICE_NAME}
    sudo systemctl disable ${SERVICE_NAME}
    sudo rm -f /etc/systemd/system/${SERVICE_NAME}.service
    sudo systemctl daemon-reload
    echo -e "${YELLOW}是否删除 qBittorrent 配置和下载数据？[y/N]${RESET}"
    read -r del
    if [[ "$del" == "y" || "$del" == "Y" ]]; then
        rm -rf ${HOME}/.config/qBittorrent
        echo -e "${RED}配置已删除${RESET}"
    fi
    echo -e "${GREEN}qBittorrent 已卸载${RESET}"
}

# 菜单
menu() {
    clear
    echo -e "${CYAN}==== qBittorrent-Nox 管理菜单 ====${RESET}"
    echo -e "1. 安装 & 部署 qBittorrent-Nox"
    echo -e "2. 启动 qBittorrent"
    echo -e "3. 停止 qBittorrent"
    echo -e "4. 重启 qBittorrent"
    echo -e "5. 查看日志"
    echo -e "6. 卸载 qBittorrent"
    echo -e "0. 退出"
    echo -ne "${YELLOW}请输入选项: ${RESET}"
    read -r choice
    case "$choice" in
        1) install_qbittorrent ;;
        2) start_qbittorrent ;;
        3) stop_qbittorrent ;;
        4) restart_qbittorrent ;;
        5) logs_qbittorrent ;;
        6) uninstall_qbittorrent ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}" ;;
    esac
}

# 循环菜单
while true; do
    menu
    echo -e "${YELLOW}按回车键继续...${RESET}"
    read -r
done
