#!/bin/env bash

# ==========================================================
# Feishu Webhook URL Configuration
# 请将此处的 URL 替换为你自己的飞书群机器人 Webhook 地址
# Get your webhook URL from your Feishu group settings.
# ==========================================================
FEISHU_WEBHOOK_URL=""

# The command to be executed
# 编译命令
BUILD_COMMAND="./build.sh milkv-duo256m-musl-riscv64-sd"

# The directory where the command will be executed
# 编译命令执行的目录
BUILD_DIR="/home/bytedream/workspace/duo-buildroot-sdk-v2"

# A function to send a message to Feishu
# 发送消息到飞书的函数
send_feishu_notification() {
  local message_content="$1"
  local json_payload=$(cat <<EOF
{
  "msg_type": "text",
  "content": {
    "text": "$message_content"
  }
}
EOF
)

  # Use curl to send the message
  curl -s -X POST -H "Content-Type: application/json" --data-binary "$json_payload" "$FEISHU_WEBHOOK_URL" > /dev/null
}

# ==========================================================
# Main Script Execution
# 主脚本执行部分
# ==========================================================

echo "进入编译目录: $BUILD_DIR"
if [ ! -d "$BUILD_DIR" ]; then
  echo "错误：目录 $BUILD_DIR 不存在。"
  send_feishu_notification "编译失败：目录 $BUILD_DIR 不存在。"
  exit 1
fi

cd "$BUILD_DIR" || {
  echo "错误：无法进入目录 $BUILD_DIR。"
  send_feishu_notification "编译失败：无法进入目录 $BUILD_DIR。"
  exit 1
}

echo "开始执行编译命令：$BUILD_COMMAND"
start_time=$(date +%s) # Record start time
$BUILD_COMMAND
exit_code=$?             # Capture the exit code of the last command
end_time=$(date +%s)   # Record end time

# Calculate the duration in seconds
# 计算编译耗时（秒）
duration=$((end_time - start_time))

if [ $exit_code -eq 0 ]; then
  echo "编译成功！耗时: $duration 秒"
  message="编译成功！耗时：$duration 秒"
  send_feishu_notification "$message"
else
  echo "编译失败！退出码: $exit_code，耗时: $duration 秒"
  message="编译失败！耗时：$duration 秒"
  send_feishu_notification "$message"
fi

exit $exit_code
