#!/bin/bash

# 定义变量
subscribe_link="https://xtls.rprx.vision/api/v1/client/subscribe?token=bad2089c3450eebf1547d9879cb595d9"

"https://xz.muguacloud.shop/api/v1/client/subscribe?token=5cdaa42b2a9aca037d53ce1cdd9f6b6f"
new_host="space.dingtalk.com"

replace_prefix="免"
repo_dir="/data/data/com.termux/files/home/ml"  # Git仓库本地路径
file_name="免流.yaml"  # 最终输出文件名

# 下载文件，不要修改UA
curl -A "v2rayNG/1.8.0" -o downloaded_file "$subscribe_link"

# base64解码下载的文件
base64 -d downloaded_file > decoded_file

# 开始生成 YAML 文件并添加 "proxies:" 行
{
  echo "proxies:"

  # 读取文件逐行处理
  while IFS= read -r line; do
      if [[ $line == vmess://* ]]; then
          encoded_vmess=${line#vmess://}  # 去掉开头的"vmess://"
          json_str=$(echo "$encoded_vmess" | base64 -d)  # base64解密

          server=$(echo "$json_str" | jq -r '.add')
          port=$(echo "$json_str" | jq -r '.port')
          uuid=$(echo "$json_str" | jq -r '.id')
          alterId=$(echo "$json_str" | jq -r '.aid')
          cipher=$(echo "$json_str" | jq -r '.cipher // "auto"')
          net_value=$(echo "$json_str" | jq -r '.net')
          ws_path=$(echo "$json_str" | jq -r '.path // "/"')
          ps_value=$(echo "$json_str" | jq -r '.ps // "Unnamed"')
          host=$(echo "$json_str" | jq -r '.host // ""')
          type_value=$(echo "$json_str" | jq -r '.type // ""')

          if [[ "$net_value" == "ws" ]]; then
              new_ps="$replace_prefix | $ps_value"
              network_opts="ws-opts: { path: $ws_path, headers: { Host: $new_host } }, ws-path: $ws_path, ws-headers: { Host: $new_host }"
          elif [[ "$net_value" == "tcp" && "$type_value" == "http" ]]; then
              new_ps="$replace_prefix | $ps_value"
              network_opts="http-opts: { path: [$ws_path], method: GET, headers: { Connection: [keep-alive], Host: [$new_host] } }"
          else
              new_ps="$replace_prefix | $ps_value"
              network_opts=""
          fi

          echo "  - { name: '$new_ps', type: vmess, server: $server, port: $port, uuid: $uuid, alterId: $alterId, cipher: $cipher, udp: true, network: $net_value, $network_opts }"
      fi
  done < decoded_file
} > "$repo_dir/$file_name"  # 确保整个内容输出到文件中

# 清理临时文件
rm downloaded_file decoded_file

# 切换到仓库目录并自动推送到GitHub
cd "$repo_dir"
git add "$file_name"
git commit -m "Auto update subscription file"
git push origin main

echo "处理完成并已推送到GitHub，文件名为 $file_name"
