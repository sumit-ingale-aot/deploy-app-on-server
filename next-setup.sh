#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! declare -f setup_ssl >/dev/null 2>&1; then
  source "$SCRIPT_DIR/common.sh"
fi

echo "🧩 Next.js Setup Started"

# 📝 Nginx
NGINX_FILE="/etc/nginx/sites-available/$CONF_NAME"

sudo tee "$NGINX_FILE" >/dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $SERVER_NAME;

    root $ROOT_PATH;
    index index.html;

    client_max_body_size 20m;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript application/xml+rss application/xml application/octet-stream image/svg+xml;
    gzip_min_length 1024;

    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location = /nginx-health {
        add_header Content-Type text/plain;
        return 200 "ok\n";
    }
}
EOF

sudo ln -sf "$NGINX_FILE" /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 🔐 SSL
setup_ssl "$SERVER_NAME"

# 🛠️ Dependencies & Build
$PACKAGE_MANAGER install $INSTALL_FLAGS

if ! $PACKAGE_MANAGER run build; then
    echo "❌ Build failed. Please check your code."
    exit 1
fi

# 🚀 PM2
command -v pm2 >/dev/null || npm install -g pm2
PORT=$PORT pm2 start $PACKAGE_MANAGER --name "$SERVER_NAME" -- start
pm2 save
pm2 startup
