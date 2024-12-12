#!/bin/bash

# 自动处理未暂存的更改
if [[ -n $(git status --porcelain) ]]; then
    echo "存在未暂存的更改，自动提交..."
    git add .
    git commit -m "自动提交未暂存的更改"
fi

# 自动处理未跟踪的文件
untracked_files=$(git ls-files --others --exclude-standard)
if [[ -n $untracked_files ]]; then
    echo "检测到未跟踪的文件，自动添加到 Git..."
    git add .
    git commit -m "自动添加未跟踪的文件"
fi

# 定义变量
subscribe_links=(
    "https://gawrgura.moe/api/v1/client/subscribe?token=88c19ebe93a5c5d7eeeb0417aac3d12a"
)  # 添加多个订阅链接
new_host="space.dingtalk.com"
replace_prefix="免"
repo_dir="/data/data/com.termux/files/home/ml"  # Git仓库本地路径
file_name="免流.yaml"  # 最终输出文件名

# 开始生成 YAML 文件并添加 "proxies:" 行
{
  echo "proxies:"

  # 手动添加单个 VMess 节点
  single_node="vmess://eyJhZGQiOiIxMTMuNDQuMTU4LjE2MyIsImFpZCI6IjAiLCJhbHBuIjoiIiwiZnAiOiIiLCJob3N0Ijoic3BhY2UuZGluZ3RhbGsuY29tIiwiaWQiOiJmZTM0ZjhjNy0yMTg1LTQzZGEtZDU3YS1jMjZjOTMxNzQ1YWIiLCJuZXQiOiJ0Y3AiLCJwYXRoIjoiLyIsInBvcnQiOiI4ODg4IiwicHMiOiJtbCIsInNjeSI6ImF1dG8iLCJzbmkiOiIiLCJ0bHMiOiIiLCJ0eXBlIjoiaHR0cCIsInYiOiIyIn0="
  encoded_vmess=${single_node#vmess://}  # 去掉开头的"vmess://"
  json_str=$(echo "$encoded_vmess" | base64 -d)  # base64解密

  server=$(echo "$json_str" | jq -r '.add')
  port=$(echo "$json_str" | jq -r '.port')
  uuid=$(echo "$json_str" | jq -r '.id')
  alterId=$(echo "$json_str" | jq -r '.aid')
  cipher=$(echo "$json_str" | jq -r '.scy // "auto"')
  net_value=$(echo "$json_str" | jq -r '.net')
  ws_path=$(echo "$json_str" | jq -r '.path // "/"')
  ps_value=$(echo "$json_str" | jq -r '.ps // "Unnamed"')
  host=$(echo "$json_str" | jq -r '.host // ""')
  type_value=$(echo "$json_str" | jq -r '.type // ""')

  if [[ "$net_value" == "ws" ]]; then
      new_ps="$replace_prefix | $ps_value"
      network_opts="\"ws-opts\": { \"path\": \"$ws_path\", \"headers\": { \"Host\": \"$new_host\" } }"
  elif [[ "$net_value" == "tcp" && "$type_value" == "http" ]]; then
      new_ps="$replace_prefix | $ps_value"
      network_opts="\"http-opts\": { \"path\": [\"/\"], \"headers\": { \"Connection\": [\"keep-alive\"], \"Host\": [\"$new_host\"] } }"
  else
      network_opts=""
  fi

  # 输出到 YAML 格式
  echo "- name: \"$new_ps\""
  echo "  type: vmess"
  echo "  server: \"$server\""
  echo "  port: $port"
  echo "  uuid: \"$uuid\""
  echo "  alterId: $alterId"
  echo "  cipher: \"$cipher\""
  echo "  network: \"$net_value\""
  if [[ -n $host ]]; then
      echo "  host: \"$host\""
  fi
  if [[ -n $network_opts ]]; then
      echo "  $network_opts"
  fi

} > "$repo_dir/$file_name"

# 推送到 GitHub
cd "$repo_dir" || exit
git pull origin main
git add "$file_name"
git commit -m "更新 $file_name 文件"
git push origin main

# 脚本功能：
# 1. 解析单个 VMess 节点：通过 Base64 解码获取 JSON 信息并解析每个字段。
# 2. 生成 YAML 格式：支持 ws 或 http 等网络类型。
# 3. Git 自动提交：将生成的 YAML 文件推送到指定仓库。