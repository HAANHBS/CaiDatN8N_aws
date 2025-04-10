#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Vui lòng chạy script với quyền sudo."
  exit
fi

read -p "Nhập NGROK Authtoken: " NGROK_AUTHTOKEN
read -p "Nhập NGROK Static Domain (ví dụ: yourname.ngrok.dev): " NGROK_DOMAIN

echo "$NGROK_DOMAIN" > ~/.ngrok_static_domain

apt update && apt upgrade -y
apt install -y docker.io docker-compose unzip

systemctl enable docker
systemctl start docker

wget https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-stable-linux-amd64.zip
unzip ngrok-stable-linux-amd64.zip
mv ngrok /usr/local/bin/
rm ngrok-stable-linux-amd64.zip

ngrok config add-authtoken $NGROK_AUTHTOKEN

mkdir -p ~/n8n-docker && cd ~/n8n-docker

cat <<EOF > docker-compose.yml
version: "3"
services:
  n8n:
    image: n8nio/n8n
    restart: always
    environment:
      - WEBHOOK_URL=https://$NGROK_DOMAIN
      - N8N_BASIC_AUTH_ACTIVE=false
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - TZ=Asia/Ho_Chi_Minh
    ports:
      - "5678:5678"
    volumes:
      - n8n_data:/home/node/.n8n
volumes:
  n8n_data:
EOF

docker-compose up -d
nohup ngrok http --domain=$NGROK_DOMAIN 5678 > ngrok.log 2>&1 &

echo ""
echo "✅ Cài đặt hoàn tất! Truy cập: https://$NGROK_DOMAIN"
