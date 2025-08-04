#!/bin/bash

### 互動輸入帳號與密碼（不寫在腳本裡）
read -p "請輸入 n8n 登入帳號名稱（預設 admin）: " N8N_USER
N8N_USER=${N8N_USER:-admin}

read -s -p "請輸入 n8n 登入密碼（必填）: " N8N_PASSWORD
echo ""
if [ -z "$N8N_PASSWORD" ]; then
  echo "❌ 密碼不能為空，請重新執行腳本"
  exit 1
fi

N8N_PORT=5678
N8N_DIR=~/n8n
PUBLIC_IP=$(curl -s ifconfig.me)

echo "🚀 開始安裝 Docker + Docker Compose..."
sudo apt update
sudo apt install -y docker.io docker-compose curl
sudo systemctl enable docker
sudo usermod -aG docker $USER

mkdir -p $N8N_DIR/n8n_data
cd $N8N_DIR

echo "📝 建立 docker-compose.yml 設定檔..."

cat > docker-compose.yml <<EOF
version: "3.1"

services:
  n8n:
    image: n8nio/n8n
    restart: always
    ports:
      - "${N8N_PORT}:${N8N_PORT}"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD}
      - N8N_HOST=${PUBLIC_IP}
      - N8N_PORT=${N8N_PORT}
      - WEBHOOK_TUNNEL_URL=http://${PUBLIC_IP}:${N8N_PORT}
    volumes:
      - ./n8n_data:/home/node/.n8n
EOF

echo "🔓 開放防火牆 Port ${N8N_PORT}（Oracle Cloud 請手動設定 Security List）"
sudo ufw allow ${N8N_PORT}

echo "🚀 啟動 n8n..."
docker-compose up -d

echo "" | tee ~/n8n/installation_result.txt
echo "✅ 完成！請用以下資訊登入：" | tee -a ~/n8n/installation_result.txt
echo "網址：http://${PUBLIC_IP}:${N8N_PORT}" | tee -a ~/n8n/installation_result.txt
echo "帳號：${N8N_USER}" | tee -a ~/n8n/installation_result.txt
echo "密碼：${N8N_PASSWORD}" | tee -a ~/n8n/installation_result.txt
