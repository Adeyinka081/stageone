#!/bin/bash
set -e

echo "=== Step 1: Collect Deployment Parameters ==="
read -p "Enter Git repository URL (default: https://github.com/Adeyinka081/stageone.git): " GIT_URL
GIT_URL=${GIT_URL:-https://github.com/Adeyinka081/stageone.git}

read -p "Enter branch name (default: main): " BRANCH
BRANCH=${BRANCH:-main}

read -p "Enter internal app port (default: 5000): " APP_PORT
APP_PORT=${APP_PORT:-5000}

echo "[Step 1] Using Git: $GIT_URL, Branch: $BRANCH, App Port: $APP_PORT"

# ================= Step 2: Install Dependencies =================
echo "=== Step 2: Installing Docker, Docker Compose, Nginx ==="
sudo apt update
sudo apt install -y docker.io docker-compose nginx git
sudo systemctl enable docker
sudo systemctl enable nginx

# ================= Step 3: Clone or Pull Repo =================
echo "=== Step 3: Preparing project files ==="
if [ ! -d ./stageone ]; then
    git clone -b $BRANCH $GIT_URL stageone
else
    cd stageone
    git reset --hard
    git pull origin $BRANCH
    cd ..
fi

cd stageone

# ================= Step 4: Build Docker Image =================
echo "=== Step 4: Building Docker image ==="
docker rm -f stageone_app 2>/dev/null || true
docker build --no-cache -t app_app .

# ================= Step 5: Run Docker Container =================
echo "=== Step 5: Running Docker container ==="
docker run -d --name stageone_app -p $APP_PORT:$APP_PORT app_app

# ================= Step 6: Configure Nginx =================
echo "=== Step 6: Configuring Nginx ==="
NGINX_CONF="server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}"

echo "$NGINX_CONF" | sudo tee /etc/nginx/sites-available/stageone
sudo ln -sf /etc/nginx/sites-available/stageone /etc/nginx/sites-enabled/stageone
sudo nginx -t
sudo systemctl restart nginx

# ================= Step 7: Cleanup Old Docker Images =================
echo "=== Step 7: Cleaning up unused Docker images ==="
docker system prune -af --volumes

# ================= Step 8: Verify Services =================
echo "=== Step 8: Checking running containers and Nginx ==="
docker ps
sudo systemctl status nginx --no-pager

# ================= Step 9: Display Access Info =================
echo "=== Step 9: Deployment complete! ==="
echo "Your app should be accessible at http://localhost/"

# ================= Step 10: Tail Docker Logs =================
echo "=== Step 10: Tail application logs (Press CTRL+C to stop) ==="
docker logs -f stageone_app

