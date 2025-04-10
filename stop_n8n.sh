#!/bin/bash
cd ~/n8n-docker || { echo "Không tìm thấy ~/n8n-docker"; exit 1; }

echo "🛑 Dừng N8N..."
docker-compose down

echo "🛑 Dừng Ngrok..."
pkill ngrok || echo "Ngrok không chạy."
