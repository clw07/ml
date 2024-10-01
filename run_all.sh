#!/bin/bash

# 定义每个转换脚本的路径
script1="/data/data/com.termux/files/home/ml/订阅转换1.sh"
script2="/data/data/com.termux/files/home/ml/订阅转换2.sh"
script3="/data/data/com.termux/files/home/ml/订阅转换3.sh"

# 执行每个脚本
bash "$script1"
bash "$script2"
bash "$script3"

echo "所有脚本已执行完毕。"
