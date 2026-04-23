#!/bin/bash
# lint-check.sh
# 检查代码质量并向 Claude 反馈
#
# 作为 PostToolUse hook，在文件写入后运行 linter

export PATH="$HOME/bin:/usr/local/bin:$PATH"

# 日志文件路径
LOG_FILE="$(dirname "$0")/lint-check-errors.log"

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

echo "DEBUG: Linting file: $FILE_PATH" >&2

# 获取文件扩展名
EXTENSION="${FILE_PATH##*.}"

# 存储 lint 结果
LINT_RESULT=""
LINT_PASSED=true

case "$EXTENSION" in
    js|jsx|ts|tsx)
        # 使用 ESLint
        if command -v npx &> /dev/null; then
            LINT_RESULT=$(npx eslint "$FILE_PATH" 2>&1)
            # 检查输出是否包含实际的 lint 问题（排除配置相关的警告）
            if echo "$LINT_RESULT" | grep -qE "(warning|error|problem)" && ! echo "$LINT_RESULT" | grep -q "✖ 0 problems"; then
                LINT_PASSED=false
                log_error "ESLint failed for file: $FILE_PATH"
                log_error "ESLint output: $LINT_RESULT"
            fi
        else
            log_error "ESLint (npx) not available for file: $FILE_PATH"
        fi
        ;;
    py)
        # 使用 flake8 或 pylint
        if command -v flake8 &> /dev/null; then
            LINT_RESULT=$(flake8 "$FILE_PATH" 2>&1) || {
                LINT_PASSED=false
                log_error "flake8 failed for file: $FILE_PATH"
                log_error "flake8 output: $LINT_RESULT"
            }
        elif command -v pylint &> /dev/null; then
            LINT_RESULT=$(pylint "$FILE_PATH" 2>&1) || {
                LINT_PASSED=false
                log_error "pylint failed for file: $FILE_PATH"
                log_error "pylint output: $LINT_RESULT"
            }
        else
            log_error "No Python linter (flake8/pylint) available for file: $FILE_PATH"
        fi
        ;;
    go)
        # 使用 golint 或 go vet
        if command -v golint &> /dev/null; then
            LINT_RESULT=$(golint "$FILE_PATH" 2>&1) || {
                LINT_PASSED=false
                log_error "golint failed for file: $FILE_PATH"
                log_error "golint output: $LINT_RESULT"
            }
        elif command -v go &> /dev/null; then
            LINT_RESULT=$(go vet "$FILE_PATH" 2>&1) || {
                LINT_PASSED=false
                log_error "go vet failed for file: $FILE_PATH"
                log_error "go vet output: $LINT_RESULT"
            }
        else
            log_error "No Go linter (golint/go vet) available for file: $FILE_PATH"
        fi
        ;;
    *)
        # 未知文件类型，跳过
        log_error "No linter configured for file type: $EXTENSION (file: $FILE_PATH)"
        echo '{}'
        exit 0
        ;;
esac

# 转义 JSON 特殊字符
LINT_RESULT_ESCAPED=$(echo "$LINT_RESULT" | jq -Rs '.')

if [ "$LINT_PASSED" = true ]; then
    # Lint 通过
    cat <<EOF
{
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "Lint check passed"
    }
}
EOF
else
    # Lint 失败，提供反馈让 Claude 修复
    cat <<EOF
{
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": $LINT_RESULT_ESCAPED
    }
}
EOF
fi

exit 0
