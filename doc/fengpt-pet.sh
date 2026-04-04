#!/bin/bash
# 服务部署脚本 - fengpt-pet

# ========== 配置区域 ==========
APP_NAME="fengpt-pet"
GIT_REPO="https://gitee.com/fengpt/fengpt-pet.git"
GIT_BRANCH="master"
WORK_DIR="/usr/local/apps/fengpt-pet"
REPO_DIR="${WORK_DIR}/repo"
LOGS_DIR="${WORK_DIR}/logs"
JAR_NAME="fengpt-pet.jar"
JAR_PATH="${REPO_DIR}/target/${JAR_NAME}"
PORT="8080"
SPRING_PROFILES_ACTIVE="dev"
SERVICE_NAME="${APP_NAME}"
APP_VERSION="v1"
LOG_FILE="${LOGS_DIR}/log"
LOG_BAK_FILE="${LOGS_DIR}/back"
LOG_PATH="${LOGS_DIR}/${SERVICE_NAME}/${APP_VERSION}/${SERVICE_NAME}.log"
# =============================

# 检查并创建工作目录
ensure_work_dir() {
    if [ ! -d "$WORK_DIR" ]; then
        echo "创建工作目录: $WORK_DIR"
        mkdir -p "$WORK_DIR"
    fi
    mkdir -p "$REPO_DIR"
    mkdir -p "$LOGS_DIR"
}

# 拉取代码
pull_code() {
    echo "正在拉取代码..."
    ensure_work_dir

    if [ -d "${REPO_DIR}/.git" ]; then
        cd "$REPO_DIR"
        echo "切换到分支: $GIT_BRANCH"
        git checkout "$GIT_BRANCH"
        echo "拉取最新代码..."
        git pull origin "$GIT_BRANCH"
    else
        echo "克隆仓库: $GIT_REPO"
        git clone -b "$GIT_BRANCH" "$GIT_REPO" "$REPO_DIR"
    fi

    if [ $? -eq 0 ]; then
        echo "代码拉取成功"
    else
        echo "代码拉取失败"
        exit 1
    fi
}

# Maven 构建
build() {
    echo "正在执行 Maven 构建..."
    cd "$REPO_DIR"

    if [ ! -f "pom.xml" ]; then
        echo "错误: 找不到 pom.xml 文件"
        exit 1
    fi

    mvn clean package -Dmaven.test.skip=true

    if [ $? -eq 0 ]; then
        echo "Maven 构建成功"

        # 检查 jar 文件是否生成
        if [ ! -f "$JAR_PATH" ]; then
            echo "错误: 构建成功但找不到 jar 文件: $JAR_PATH"
            exit 1
        fi
    else
        echo "Maven 构建失败"
        exit 1
    fi
}

# 检查 jar 文件是否存在
check_jar() {
    if [ ! -f "$JAR_PATH" ]; then
        echo "错误: Jar 文件不存在: $JAR_PATH"
        echo "请先执行 build 或 deploy 命令"
        exit 1
    fi
}

# 检查端口是否已被占用 (通过查找进程)
check_port() {
    ps -ef | grep "$APP_NAME" | grep "server.port=${PORT}" | grep -v grep > /dev/null 2>&1
    return $?
}

# 获取进程 PID (用于停止)
get_pid() {
    ps -ef | grep "$APP_NAME" | grep "server.port=${PORT}" | grep -v grep | awk '{print $2}'
}

start() {
    echo "正在启动 $APP_NAME (端口: $PORT) ..."
    check_jar

    if check_port; then
        PID=$(get_pid)
        echo "服务已在运行，PID: $PID，请先停止或重启。"
        exit 1
    fi

    # 创建日志目录
    mkdir -p "$LOGS_DIR"
    mkdir -p "$(dirname "$LOG_PATH")"

    # 使用 nohup 启动，将输出重定向到日志文件
    nohup java -Dserver.port=${PORT} \
         -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} \
         -DSERVICE_NAME=${SERVICE_NAME} \
         -DAPP_VERSION=${APP_VERSION} \
         -DAPP_LOG_BAK_FILE=${LOG_BAK_FILE} \
         -DAPP_LOG_FILE=${LOG_FILE} \
         -jar ${JAR_PATH} > ${LOG_PATH} 2>&1 &

    # 获取新启动的进程 PID
    NEW_PID=$!
    sleep 3  # 等待进程启动

    # 再次检查进程是否成功运行
    if check_port; then
        echo "服务启动成功，PID: $(get_pid)，日志文件: ${LOG_PATH}"
    else
        echo "服务启动失败，请检查日志: ${LOG_PATH}"
        exit 1
    fi
}

stop() {
    echo "正在停止 $APP_NAME (端口: $PORT) ..."
    if ! check_port; then
        echo "服务未运行。"
        return 0
    fi

    PID=$(get_pid)
    if [ -n "$PID" ]; then
        kill -15 $PID  # 发送 SIGTERM 信号，尝试优雅停止
        sleep 3
        # 检查是否还在运行
        if check_port; then
            echo "服务未能在 3 秒内停止，强制终止 (kill -9) ..."
            kill -9 $PID
            sleep 1
        fi
        if check_port; then
            echo "停止失败，请手动检查。"
            exit 1
        else
            echo "服务已停止。"
        fi
    else
        echo "无法获取 PID，停止操作跳过。"
    fi
}

status() {
    if check_port; then
        PID=$(get_pid)
        echo "$APP_NAME (端口: $PORT) 正在运行，PID: $PID"
    else
        echo "$APP_NAME (端口: $PORT) 未运行"
    fi
}

restart() {
    stop
    sleep 2
    start
}

deploy() {
    echo "===== 开始完整部署 ====="
    pull_code
    build
    stop
    sleep 2
    start
    echo "===== 部署完成 ====="
}

show_help() {
    echo "用法: $0 {deploy|pull|build|start|stop|restart|status|log|grep|time|search|stats|listlogs|bgrep|btime|bsearch|bstats|bfullsearch}"
    echo ""
    echo "命令说明:"
    echo "  deploy  - 完整部署：拉取代码 → 构建 → 重启服务"
    echo "  pull    - 仅拉取最新代码"
    echo "  build   - 拉取代码并执行 Maven 构建"
    echo "  start   - 启动服务"
    echo "  stop    - 停止服务"
    echo "  restart - 重启服务"
    echo "  status  - 查看服务状态"
    echo "  log     - 实时查看日志"
    echo ""
    echo "当前日志筛选命令:"
    echo "  grep <关键词> [行数]    - 按关键词搜索日志"
    echo "  time <开始> [结束]      - 按时间范围筛选日志"
    echo "  search <时间> <关键词> [行数] - 时间+关键词组合搜索"
    echo "  stats                   - 查看日志统计信息"
    echo ""
    echo "所有日志(含备份)筛选命令 (前缀 b):"
    echo "  listlogs                - 列出所有日志文件"
    echo "  bgrep <关键词> [行数]   - 在所有日志中按关键词搜索"
    echo "  btime <开始> [结束]     - 在所有日志中按时间范围搜索"
    echo "  bsearch <时间> <关键词> [行数] - 所有日志时间+关键词搜索"
    echo "  bstats                  - 查看所有日志统计信息"
    echo "  bfullsearch <开始> <结束> <关键词> - 开始时间+结束时间+关键词搜索"
    echo ""
    echo "示例:"
    echo "  $0 grep ERROR 200"
    echo "  $0 time '10:00' '12:00'"
    echo "  $0 search '14:30' 'Exception' 300"
    echo "  $0 bgrep ERROR 100"
    echo "  $0 bsearch '09:00' 'Exception' 500"
    echo "  $0 bfullsearch '2026-04-04' '2026-04-05' 'test'"
}

# 获取所有日志文件
get_log_files() {
    local files=()
    if [ -f "$LOG_PATH" ]; then
        files+=("$LOG_PATH")
    fi
    local backup_dir="$(dirname "$LOG_BAK_FILE")"
    if [ -d "$backup_dir" ]; then
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$backup_dir" -type f \( -name "*.log" -o -name "*.log.*" \) -print0 2>/dev/null | sort -z)
    fi
    echo "${files[@]}"
}

CMD="$1"

case "$CMD" in
    deploy)
        deploy
        ;;
    pull)
        pull_code
        ;;
    build)
        pull_code
        build
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    log)
        if [ ! -f "$LOG_PATH" ]; then
            echo "日志文件不存在: $LOG_PATH"
            exit 1
        fi
        tail -f "$LOG_PATH"
        ;;
    grep)
        KEYWORD="$2"
        LINES="${3:-100}"
        if [ -z "$KEYWORD" ]; then
            echo "请指定关键词: $0 grep <关键词> [行数]"
            exit 1
        fi
        tail -n "$LINES" "$LOG_PATH" | grep -i "$KEYWORD"
        ;;
    time)
        START="$2"
        END="${3:-$(date +'%H:%M')}"
        if [ -z "$START" ]; then
            echo "请指定时间: $0 time <开始> [结束]"
            exit 1
        fi
        awk -v s="$START" -v e="$END" '$0 ~ s, $0 ~ e' "$LOG_PATH"
        ;;
    search)
        TIME="$2"
        KEYWORD="$3"
        LINES="${4:-200}"
        if [ -z "$TIME" ] || [ -z "$KEYWORD" ]; then
            echo "请指定时间和关键词: $0 search <时间> <关键词> [行数]"
            exit 1
        fi
        tail -n "$LINES" "$LOG_PATH" | awk -v t="$TIME" 'BEGIN{s=0} $0~t{s=1} s' | grep -i "$KEYWORD"
        ;;
    stats)
        echo "文件: $LOG_PATH"
        echo "行数: $(wc -l < "$LOG_PATH")"
        echo "ERROR: $(grep -c 'ERROR' "$LOG_PATH")"
        ;;
    listlogs)
        echo "[当前] $LOG_PATH"
        BACKUP_DIR="$(dirname "$LOG_BAK_FILE")"
        if [ -d "$BACKUP_DIR" ]; then
            find "$BACKUP_DIR" -type f \( -name "*.log" -o -name "*.log.*" \) 2>/dev/null | sort | while read f; do
                echo "[备份] $f"
            done
        fi
        ;;
    bgrep)
        KEYWORD="$2"
        LINES="${3:-50}"
        if [ -z "$KEYWORD" ]; then
            echo "请指定关键词: $0 bgrep <关键词> [行数]"
            exit 1
        fi
        FILES=($(get_log_files))
        for f in "${FILES[@]}"; do
            echo "=== $f ==="
            tail -n "$LINES" "$f" 2>/dev/null | grep -i "$KEYWORD"
            echo ""
        done
        ;;
    btime)
        START="$2"
        END="${3:-$(date +'%H:%M')}"
        if [ -z "$START" ]; then
            echo "请指定时间: $0 btime <开始> [结束]"
            exit 1
        fi
        FILES=($(get_log_files))
        for f in "${FILES[@]}"; do
            echo "=== $f ==="
            awk -v s="$START" -v e="$END" '$0 ~ s, $0 ~ e' "$f" 2>/dev/null
            echo ""
        done
        ;;
    bsearch)
        TIME="$2"
        KEYWORD="$3"
        LINES="${4:-200}"
        if [ -z "$TIME" ] || [ -z "$KEYWORD" ]; then
            echo "请指定时间和关键词: $0 bsearch <时间> <关键词> [行数]"
            exit 1
        fi
        FILES=($(get_log_files))
        for f in "${FILES[@]}"; do
            echo "=== $f ==="
            tail -n "$LINES" "$f" 2>/dev/null | awk -v t="$TIME" 'BEGIN{s=0} $0~t{s=1} s' | grep -i "$KEYWORD"
            echo ""
        done
        ;;
    bstats)
        FILES=($(get_log_files))
        for f in "${FILES[@]}"; do
            echo "=== $f ==="
            echo "行数: $(wc -l < "$f" 2>/dev/null || echo 0)"
            echo "ERROR: $(grep -c 'ERROR' "$f" 2>/dev/null || echo 0)"
            echo ""
        done
        ;;
    bfullsearch)
        START="$2"
        END="$3"
        KEYWORD="$4"
        if [ -z "$START" ] || [ -z "$END" ] || [ -z "$KEYWORD" ]; then
            echo "请指定开始时间、结束时间和关键词"
            echo "用法: $0 bfullsearch <开始> <结束> <关键词>"
            echo "示例: $0 bfullsearch '2026-04-04' '2026-04-05' 'test'"
            exit 1
        fi
        FILES=($(get_log_files))
        for f in "${FILES[@]}"; do
            # 第一步：找到所有匹配关键词的行号
            MATCHING_LINES=$(grep -n -i "$KEYWORD" "$f" 2>/dev/null | cut -d: -f1)

            if [ -n "$MATCHING_LINES" ]; then
                echo "=== $f ==="
                # 第二步：检查每个匹配行是否在时间范围内
                for line_num in $MATCHING_LINES; do
                    # 获取该行内容检查时间
                    line_content=$(sed -n "${line_num}p" "$f" 2>/dev/null)
                    if [[ "$line_content" > "$START" && "$line_content" < "$END" ]]; then
                        # 输出前后20行
                        start=$((line_num - 20))
                        [ $start -lt 1 ] && start=1
                        end=$((line_num + 20))
                        echo "--- 第 ${line_num} 行附近 ---"
                        sed -n "${start},${end}p" "$f" 2>/dev/null
                        echo ""
                    fi
                done
            fi
        done
        ;;
    *)
        show_help
        ;;
esac

exit 0
