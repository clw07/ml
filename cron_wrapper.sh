#!/bin/bash

# 设置日志文件路径
log_file="/data/data/com.termux/files/home/ml/logs/cron.log"

# 确保日志目录存在
mkdir -p "$(dirname "$log_file")"

# 记录时间戳
echo "Starting script at $(date)" >> "$log_file"

# 执行实际脚本并将输出追加到日志
/data/data/com.termux/files/home/ml/订阅转换.sh >> "$log_file" 2>&1

# 记录结束时间戳
echo "Finished script at $(date)" >> "$log_file"
