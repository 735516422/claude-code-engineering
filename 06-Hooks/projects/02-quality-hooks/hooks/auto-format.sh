#!/bin/bash
# auto-format.sh
# 自动格式化代码文件
#
# 作为 PostToolUse hook，在文件写入后自动运行格式化工具

export PATH="$HOME/bin:/usr/local/bin:$PATH"

# 日志文件路径
LOG_FILE="$(dirname "$0")/auto-format-errors.log"

# 记录日志的函数
log_error() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local message="[$timestamp] $1"
    echo "$message" >> "$LOG_FILE"
}

# 读取 stdin 输入
INPUT=$(cat)

# 提取文件路径
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# 如果没有文件路径，跳过
if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    echo '{}'
    exit 0
fi

echo "DEBUG: Formatting file: $FILE_PATH" >&2

# 获取文件扩展名
EXTENSION="${FILE_PATH##*.}"

# 根据文件类型选择格式化工具
case "$EXTENSION" in
    js|jsx|ts|tsx|json|md|css|scss|html)
        # 使用 Prettier
        if command -v npx &> /dev/null; then
            if npx prettier --write "$FILE_PATH" 2>&1; then
                echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Formatted with Prettier"}}'
            else
                log_error "Prettier formatting failed for file: $FILE_PATH"
                echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Prettier formatting failed"}}'
            fi
        else
            log_error "Prettier not available for file: $FILE_PATH"
            echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Prettier not available"}}'
        fi
        ;;
    py)
        # 使用 Black
        if command -v black &> /dev/null; then
            if black "$FILE_PATH" 2>&1; then
                echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Formatted with Black"}}'
            else
                log_error "Black formatting failed for file: $FILE_PATH"
                echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Black formatting failed"}}'
            fi
        else
            log_error "Black not available for file: $FILE_PATH"
            echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Black not available"}}'
        fi
        ;;
    go)
        # 使用 gofmt
        if command -v gofmt &> /dev/null; then
            if gofmt -w "$FILE_PATH" 2>&1; then
                echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Formatted with gofmt"}}'
            else
                log_error "gofmt formatting failed for file: $FILE_PATH"
                echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "gofmt formatting failed"}}'
            fi
        else
            log_error "gofmt not available for file: $FILE_PATH"
            echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "gofmt not available"}}'
        fi
        ;;
    rs)
        # 使用 rustfmt
        if command -v rustfmt &> /dev/null; then
            if rustfmt "$FILE_PATH" 2>&1; then
                echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Formatted with rustfmt"}}'
            else
                log_error "rustfmt formatting failed for file: $FILE_PATH"
                echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "rustfmt formatting failed"}}'
            fi
        else
            log_error "rustfmt not available for file: $FILE_PATH"
            echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "rustfmt not available"}}'
        fi
        ;;
    *)
        # 未知文件类型，跳过
        log_error "No formatter configured for file type: $EXTENSION (file: $FILE_PATH)"
        echo '{"hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "No formatter configured for this file type"}}'
        ;;
esac

exit 0
