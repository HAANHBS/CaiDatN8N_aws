#!/bin/bash
cd ~/n8n-docker || { echo "Không tìm thấy ~/n8n-docker"; exit 1; }

echo "🚀 Khởi động N8N..."
docker-compose up -d

if [ -f ~/.ngrok_static_domain ]; then
  DOMAIN=$(cat ~/.ngrok_static_domain)
  echo "🌐 Khởi động Ngrok với domain: $DOMAIN"
  nohup ngrok http --domain=$DOMAIN 5678 > ngrok.log 2>&1 &
  echo "✅ Truy cập N8N tại: https://$DOMAIN"
else
  echo "⚠️ Không tìm thấy domain tĩnh! Không khởi động ngrok."
fi
