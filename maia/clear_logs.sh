if [ "$(date +%u)" != "5" ]; then
    exit 0
fi

LOG_FILE="bot_logs.txt"

[ -f "$LOG_FILE" ] && > "$LOG_FILE"
