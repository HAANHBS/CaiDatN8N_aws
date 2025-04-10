#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}Script này cần chạy với quyền root. Vui lòng sử dụng sudo.${NC}"
  exit 1
fi

# Function to install Docker
install_docker() {
  echo -e "${YELLOW}Đang cài đặt Docker...${NC}"
  apt-get update
  apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update
  apt-get install -y docker-ce docker-ce-cli containerd.io
  systemctl enable docker
  systemctl start docker

  # Install Docker Compose
  echo -e "${YELLOW}Đang cài đặt Docker Compose...${NC}"
  curl -L "https://github.com/docker/compose/releases/download/v2.23.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

  echo -e "${GREEN}Docker và Docker Compose đã được cài đặt thành công.${NC}"
}

# Function to setup n8n with Docker Compose
setup_n8n() {
  echo -e "${YELLOW}Thiết lập N8N với Docker Compose...${NC}"

  # Create docker-compose.yml for n8n
  cat > /opt/n8n/docker-compose.yml << 'EOL'
version: '3'
services:
  n8n:
    image: n8nio/n8n
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER
      - N8N_BASIC_AUTH_PASSWORD
      - N8N_HOST=localhost
      - N8N_PORT=5678
      - N8N_PROTOCOL=http
      - N8N_USER_MANAGEMENT_DISABLED=false
      - TZ=Asia/Ho_Chi_Minh
    volumes:
      - ./.n8n:/home/node/.n8n
EOL

  # Create .env file for n8n
  cat > /opt/n8n/.env << 'EOL'
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=password
EOL

  # Start n8n container
  cd /opt/n8n
  docker-compose up -d

  echo -e "${GREEN}N8N đã được thiết lập thành công và chạy trên cổng 5678.${NC}"
  echo -e "${YELLOW}Bạn có thể truy cập N8N tại: http://localhost:5678${NC}"
  echo -e "${YELLOW}Tài khoản admin mặc định: admin / password${NC}"
  echo -e "${YELLOW}Hãy thay đổi mật khẩu trong file .env tại /opt/n8n/.env sau khi cài đặt!${NC}"
}

# Function to install and configure ngrok
install_ngrok() {
  echo -e "${YELLOW}Đang cài đặt Ngrok...${NC}"
  
  # Download and install ngrok
  curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
  apt-get update
  apt-get install -y ngrok

  # Configure ngrok
  echo -e "${YELLOW}Vui lòng nhập Ngrok Auth Token (có thể lấy từ https://dashboard.ngrok.com/get-started/your-authtoken):${NC}"
  read -p "Ngrok Token: " ngrok_token
  ngrok config add-authtoken $ngrok_token

  # Ask for custom domain (optional)
  echo -e "${YELLOW}Bạn có muốn sử dụng domain tùy chỉnh không? (Nhấn Enter để bỏ qua và sử dụng domain ngẫu nhiên)${NC}"
  read -p "Domain tùy chỉnh (ví dụ: my-n8n): " custom_domain

  # Create systemd service for ngrok
  cat > /etc/systemd/system/ngrok.service << EOL
[Unit]
Description=Ngrok Tunnel to N8N
After=network.target

[Service]
ExecStart=/usr/bin/ngrok http --domain=${custom_domain}.ngrok.io 127.0.0.1:5678
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOL

  # Start ngrok service
  systemctl daemon-reload
  systemctl enable ngrok.service
  systemctl start ngrok.service

  # Get public URL
  sleep 5 # Wait for ngrok to start
  public_url=$(curl -s localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')

  echo -e "${GREEN}Ngrok đã được cài đặt và cấu hình thành công!${NC}"
  echo -e "${YELLOW}URL truy cập công khai của bạn: ${public_url}${NC}"
  echo -e "${YELLOW}Bạn có thể quản lý tunnel tại: https://dashboard.ngrok.com/cloud-edge/tunnels${NC}"
}

# Main script execution
echo -e "${GREEN}Bắt đầu quá trình cài đặt...${NC}"

# Create directory for n8n
mkdir -p /opt/n8n

# Install Docker and Docker Compose
install_docker

# Setup n8n
setup_n8n

# Install and configure ngrok
install_ngrok

echo -e "${GREEN}Cài đặt hoàn tất!${NC}"
echo -e "${YELLOW}Thông tin truy cập:${NC}"
echo -e " - N8N Local: http://localhost:5678"
echo -e " - N8N Public: ${public_url}"
echo -e "${YELLOW}Tài khoản admin mặc định: admin / password${NC}"
echo -e "${RED}Lưu ý: Hãy thay đổi mật khẩu admin trong file /opt/n8n/.env ngay lập tức!${NC}"
