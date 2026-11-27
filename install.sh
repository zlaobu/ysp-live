#!/bin/sh
# ysp-live 一键安装与管理脚本

CONTAINER_NAME="ysp-live"
ROOT_DIR="/root/ysp-live"
PROJECT_DIR="$ROOT_DIR/ysp-live-main"
DATA_DIR="$PROJECT_DIR/data"
PORT="8767"
REPO_ZIP="https://codeload.github.com/tmxk2020/ysp-live/zip/refs/heads/main"

say() { printf '%s\n' "$*"; }
line() { say '============================================================'; }

get_local_ip() {
    ip_addr=""
    if command -v uci >/dev/null 2>&1; then
        ip_addr=$(uci get network.lan.ipaddr 2>/dev/null)
    fi
    if [ -z "$ip_addr" ] && command -v hostname >/dev/null 2>&1; then
        ip_addr=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    [ -n "$ip_addr" ] || ip_addr="127.0.0.1"
    printf '%s' "$ip_addr"
}

show_links() {
    ip_addr=$(get_local_ip)
    line
    say "ysp-live 服务地址"
    printf '  播放列表： http://%s:%s/all.m3u\n' "$ip_addr" "$PORT"
    printf '  健康检查： http://%s:%s/health\n' "$ip_addr" "$PORT"
    printf '  诊断页面： http://%s:%s/diag\n' "$ip_addr" "$PORT"
    line
}

docker_compose_cmd() {
    if docker compose version >/dev/null 2>&1; then
        COMPOSE="docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        COMPOSE="docker-compose"
    else
        say "错误：未找到 Docker Compose，请先安装 Docker Compose。"
        return 1
    fi
    return 0
}

fetch_source() {
    TMP_DIR="$ROOT_DIR/.update-tmp"
    ZIP_FILE="$ROOT_DIR/ysp-live-latest.zip"
    rm -rf "$TMP_DIR"
    mkdir -p "$TMP_DIR" || return 1
    say "[1/4] 正在从 GitHub 下载最新项目文件..."
    if command -v curl >/dev/null 2>&1; then
        curl -fL --connect-timeout 20 --retry 2 "$REPO_ZIP" -o "$ZIP_FILE" || return 1
    elif command -v wget >/dev/null 2>&1; then
        wget -O "$ZIP_FILE" "$REPO_ZIP" || return 1
    else
        say "错误：系统需要安装 curl 或 wget。"
        return 1
    fi
    command -v unzip >/dev/null 2>&1 || { say "错误：系统需要安装 unzip。"; return 1; }
    unzip -q "$ZIP_FILE" -d "$TMP_DIR" || return 1
    SOURCE_DIR="$TMP_DIR/ysp-live-main"
    [ -f "$SOURCE_DIR/Dockerfile" ] || { say "错误：下载的项目中缺少 Dockerfile。"; return 1; }
    [ -f "$SOURCE_DIR/docker-compose.yml" ] || { say "错误：下载的项目中缺少 docker-compose.yml。"; return 1; }
    [ -f "$SOURCE_DIR/install.sh" ] || say "提示：下载包中未包含 install.sh。"
    return 0
}

do_install() {
    command -v docker >/dev/null 2>&1 || { say "错误：未检测到 Docker，请先安装 Docker。"; return 1; }
    docker_compose_cmd || return 1
    mkdir -p "$ROOT_DIR" || return 1
    fetch_source || { say "错误：项目下载或解压失败，原有安装未作任何更改。"; return 1; }

    # 用户数据独立备份，更新完成后再恢复。
    OLD_PROJECT="$ROOT_DIR/project-old-$(date +%Y%m%d%H%M%S)"
    if [ -d "$DATA_DIR" ]; then
        mkdir -p "$ROOT_DIR/data-backup"
        cp -a "$DATA_DIR/." "$ROOT_DIR/data-backup/" 2>/dev/null
    fi
    if [ -d "$PROJECT_DIR" ]; then
        mv "$PROJECT_DIR" "$OLD_PROJECT" || return 1
    fi
    mv "$SOURCE_DIR" "$PROJECT_DIR" || {
        [ -d "$OLD_PROJECT" ] && mv "$OLD_PROJECT" "$PROJECT_DIR"
        return 1
    }
    if [ -d "$ROOT_DIR/data-backup" ] && [ ! -d "$PROJECT_DIR/data" ]; then
        mkdir -p "$PROJECT_DIR/data"
        cp -a "$ROOT_DIR/data-backup/." "$PROJECT_DIR/data/" 2>/dev/null
    fi
    mkdir -p "$PROJECT_DIR/data"
    cd "$PROJECT_DIR" || return 1

    say "[2/4] 正在构建新版镜像，当前服务暂时保持运行..."
    $COMPOSE build
    result=$?
    if [ "$result" -ne 0 ]; then
        say "错误：镜像构建失败，当前运行中的容器未停止。"
        rm -rf "$PROJECT_DIR"
        [ -d "$OLD_PROJECT" ] && mv "$OLD_PROJECT" "$PROJECT_DIR"
        return 1
    fi
    say "[3/4] 正在使用新版本重启服务..."
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    $COMPOSE up -d --remove-orphans
    result=$?
    if [ "$result" -ne 0 ]; then
        say "错误：新版容器启动失败，正在恢复上一版本..."
        FAILED_PROJECT="$ROOT_DIR/project-failed-$(date +%Y%m%d%H%M%S)"
        mv "$PROJECT_DIR" "$FAILED_PROJECT" 2>/dev/null
        [ -d "$OLD_PROJECT" ] && mv "$OLD_PROJECT" "$PROJECT_DIR"
        if [ -d "$PROJECT_DIR" ]; then
            cd "$PROJECT_DIR" && $COMPOSE up -d --build
        fi
        return 1
    fi
    say "[4/4] 正在等待服务启动..."
    sleep 3
    if command -v curl >/dev/null 2>&1; then
        curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1
        health=$?
    else
        wget -qO- "http://127.0.0.1:$PORT/health" >/dev/null 2>&1
        health=$?
    fi
    if [ "$health" -eq 0 ]; then
        say "部署完成：健康检查接口响应正常。"
    else
        say "容器已启动，但健康检查接口暂未响应，请查看运行日志。"
    fi
    show_links
}

show_logs() {
    docker logs --tail 200 -f "$CONTAINER_NAME"
}

health_check() {
    if command -v curl >/dev/null 2>&1; then
        curl -sS "http://127.0.0.1:$PORT/health"
    else
        wget -qO- "http://127.0.0.1:$PORT/health"
    fi
    say ""
}

do_uninstall() {
    say "此操作将删除 ysp-live 容器和项目文件。"
    say "默认保留用户数据；如需彻底删除，请选择“彻底卸载”。"
    printf '确认继续吗？[y/N]：'
    read answer
    case "$answer" in y|Y|yes|YES) ;; *) say "已取消操作。"; return 0 ;; esac
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    if [ -d "$DATA_DIR" ]; then
        mkdir -p "$ROOT_DIR/data-backup"
        cp -a "$DATA_DIR/." "$ROOT_DIR/data-backup/" 2>/dev/null
    fi
    if [ -d "$PROJECT_DIR" ]; then
        cd / 2>/dev/null
        rm -rf "$PROJECT_DIR"
    fi
    say "容器和项目文件已删除，备份数据保存在：$ROOT_DIR/data-backup"
}

do_purge() {
    say "警告：此操作将永久删除容器、镜像、项目文件及所有保存的数据，且无法恢复！"
    printf '请输入 DELETE 确认彻底删除：'
    read answer
    [ "$answer" = "DELETE" ] || { say "已取消操作。"; return 0; }
    docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker image rm "ysp-live:20261125-TMXK" >/dev/null 2>&1 || true
    cd / 2>/dev/null
    rm -rf "$ROOT_DIR"
    say "彻底卸载完成。"
}

menu() {
    while :; do
        line
        say "ysp-live 安装与管理工具"
        line
        say "1) 安装或更新到 GitHub 最新版本"
        say "2) 查看服务访问地址"
        say "3) 查看容器实时日志"
        say "4) 检查服务运行状态"
        say "5) 卸载程序（保留用户数据）"
        say "6) 彻底卸载（同时删除所有用户数据）"
        say "0) 退出"
        line
        printf '请输入选项 [0-6]：'
        read choice
        case "$choice" in
            1) do_install ;;
            2) show_links ;;
            3) show_logs ;;
            4) health_check ;;
            5) do_uninstall ;;
            6) do_purge ;;
            0) say "已退出。"; return 0 ;;
            *) say "无效选项，请输入 0-6。" ;;
        esac
    done
}

if [ "$(id -u 2>/dev/null)" != "0" ]; then
    say "错误：请使用 root 用户运行此脚本。"
    exit 1
fi
menu
