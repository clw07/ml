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
)  # 订阅链接数组
single_node="vmess://eyJhZGQiOiIxMTMuNDQuMTU4LjE2MyIsImFpZCI6IjAiLCJhbHBuIjoiIiwiZnAiOiIiLCJob3N0IjoiIiwiaWQiOiI5YTc5ZDYwOS1kMjkxLTRmNDktOGIyOC1jM2M1NGFlNzcyOGIiLCJuZXQiOiJ0Y3AiLCJwYXRoIjoiLyIsInBvcnQiOiI4ODg4IiwicHMiOiLmlocgIOWMl+S6rDNNIiwic2N5IjoiYXV0byIsInNuaSI6IiIsInRscyI6IiIsInR5cGUiOiJodHRwIiwidiI6IjIifQ=="
new_host="space.dingtalk.com"
replace_prefix="免"
repo_dir="/data/data/com.termux/files/home/ml"  # Git仓库本地路径
file_name="免流.yaml"  # 最终输出文件名

# 初始化 YAML 文件
echo "proxies:" > "$repo_dir/$file_name"

# 定义函数：解析节点并添加到 YAML 文件
parse_and_add_node() {
    local encoded_vmess=$1
    local json_str=$(echo "$encoded_vmess" | base64 -d)  # Base64 解密

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
        new_ps="$replace_prefix | $ps_value"
        network_opts=""
    fi

    # 输出到 YAML 文件，去掉多余的 | tcp
    if [[ "$net_value" == "tcp" ]]; then
        echo "- name: \"$new_ps | tcp\"" >> "$repo_dir/$file_name"
        echo "  type: vmess" >> "$repo_dir/$file_name"
        echo "  server: \"$server\"" >> "$repo_dir/$file_name"
        echo "  port: $port" >> "$repo_dir/$file_name"
        echo "  uuid: \"$uuid\"" >> "$repo_dir/$file_name"
        echo "  alterId: $alterId" >> "$repo_dir/$file_name"
        echo "  cipher: \"$cipher\"" >> "$repo_dir/$file_name"
        echo "  udp: true" >> "$repo_dir/$file_name"
        echo "  network: \"http\"" >> "$repo_dir/$file_name"
        echo "  $network_opts" >> "$repo_dir/$file_name"
        echo "  servername: \"$new_host\"" >> "$repo_dir/$file_name"
    else
        echo "- name: \"$new_ps\"" >> "$repo_dir/$file_name"
        echo "  type: vmess" >> "$repo_dir/$file_name"
        echo "  server: \"$server\"" >> "$repo_dir/$file_name"
        echo "  port: $port" >> "$repo_dir/$file_name"
        echo "  uuid: \"$uuid\"" >> "$repo_dir/$file_name"
        echo "  alterId: $alterId" >> "$repo_dir/$file_name"
        echo "  cipher: \"$cipher\"" >> "$repo_dir/$file_name"
        echo "  udp: true" >> "$repo_dir/$file_name"
        echo "  network: \"$net_value\"" >> "$repo_dir/$file_name"
        if [[ -n $host ]]; then
            echo "  host: \"$host\"" >> "$repo_dir/$file_name"
        fi
        if [[ -n $network_opts ]]; then
            echo "  $network_opts" >> "$repo_dir/$file_name"
        fi
        echo "  servername: \"$new_host\"" >> "$repo_dir/$file_name"
    fi
}

# 解析订阅链接中的所有节点
for link in "${subscribe_links[@]}"; do
    echo "处理订阅链接：$link"
    subscription_content=$(curl -s "$link" | base64 -d)

    # 按行读取每个节点
    echo "$subscription_content" | while read -r line; do
        if [[ $line == vmess://* ]]; then
            encoded_vmess=${line#vmess://}  # 去掉 "vmess://"
            parse_and_add_node "$encoded_vmess"
        fi
    done
done

# 添加手动定义的单个节点
echo "处理手动添加的单个节点..."
encoded_vmess=${single_node#vmess://}
parse_and_add_node "$encoded_vmess"

# 推送到 GitHub
cd "$repo_dir" || exit
git pull origin main
git add "$file_name"
git commit -m "更新 $file_name 文件"
git push origin main

echo "脚本执行完成，文件已生成并推送到 GitHub。"