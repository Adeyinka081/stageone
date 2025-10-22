#!/bin/bash
# deploy.sh - Stage One DevOps Deployment Script
# POSIX-compliant, executable, with logging and error handling

set -e
trap 'echo "[ERROR] Deployment failed at line $LINENO"; exit 1' ERR

# Log file
LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== Step 1: Collecting Deployment Parameters ==="
read -p "Enter Git repository URL (default: https://github.com/Adeyinka081/stageone.git): " GIT_REPO
GIT_REPO=${GIT_REPO:-https://github.com/Adeyinka081/stageone.git}

read -p "Enter branch name (default: main): " BRANCH
BRANCH=${BRANCH:-main}

read -p "Enter internal app port (default: 5000): " APP_PORT
APP_PORT=${APP_PORT:-5000}

read -p "Enter Personal Access Token (optional, leave blank if none): " PAT
read -p "Enter SSH host (optional, leave blank if none): " SSH_HOST
read -p "Enter SSH user (optional, leave blank if none): " SSH_USER

echo "[Step 1] Using Git: $GIT_REPO, Branch: $BRANCH, App Port: $APP_PORT"

echo "=== Step 2: Installing Docker, Docker Compose, Nginx ==="
sudo apt update -y
sudo apt install -y docker.io docker-compose nginx git
sudo systemctl enable nginx
sudo systemctl start nginx

# Docker group setup
if ! groups $USER | grep -q docker; then
    sudo usermod -aG docker $USER
    echo "[INFO] Added $USER to docker group. You may need to re-login for this to take effect."
fi

echo "=== Step 3: Preparing project files ==="
REPO_DIR="stageone"
if [ ! -d "$REPO_DIR" ]; then
    git clone "$GIT_REPO" "$REPO_DIR"
else
    git -C "$REPO_DIR" fetch --all
fi
git -C "$REPO_DIR" checkout "$BRANCH"
git -C "$REPO_DIR" pull origin "$BRANCH"

echo "=== Step 4: Building Docker image ==="
docker rm -f stageone_app 2>/dev/null || true
docker rmi app_app 2>/dev/null || true

docker build -t app_app "$REPO_DIR"

echo "=== Step 5: Running Docker container ==="
docker run -d --name stageone_app -p "$APP_PORT:$APP_PORT" app_app

echo "=== Step 6: Checking container logs ==="
docker logs -f stageone_app & sleep 5; pkill -P $$ docker

echo "=== Step 7: Configuring Nginx ==="
NGINX_CONF="/etc/nginx/sites-available/stageone"
sudo tee "$NGINX_CONF" > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/stageone
sudo nginx -t
sudo systemctl reload nginx

echo "=== Step 8: Cleaning up old containers/images ==="
docker system prune -f
docker image prune -f

echo "=== Step 9: Verifying app is running ==="
docker ps -a | grep stageone_app
sudo systemctl status nginx | grep active

echo "=== Step 10: Deployment complete! ==="
echo "Your app should be accessible at http://localhost"
echo "Log file saved as $LOG_FILE"

