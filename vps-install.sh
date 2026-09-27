#!/usr/bin/env bash
set -euo pipefail

TOKEN='__TOKEN__'
WS_PATH='__WS_PATH__'
LISTEN_PORT='__LISTEN_PORT__'

if [ "$(id -u)" -ne 0 ]; then
  echo "Run this command as root (or through sudo)." >&2
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This one-command installer currently supports Ubuntu/Debian VPS only." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y python3 python3-venv nginx curl

python3 -m venv /opt/ghanizada-websockify
/opt/ghanizada-websockify/bin/pip install --upgrade pip
/opt/ghanizada-websockify/bin/pip install websockify

cat >/etc/systemd/system/ghanizada-websockify.service <<'UNIT'
[Unit]
Description=Ghanizada WebSocket to SSH bridge
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/opt/ghanizada-websockify/bin/websockify 127.0.0.1:6080 127.0.0.1:22
Restart=always
RestartSec=2
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
UNIT

mkdir -p /etc/nginx/conf.d
cat >/etc/nginx/conf.d/ghanizada-ssh.conf <<'NGINX'
server {
    listen __LISTEN_PORT__;
    server_name _;

    location = __WS_PATH__ {
        if ($http_x_ghanizada_backend_token != "__TOKEN__") { return 403; }

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
        proxy_pass http://127.0.0.1:6080;
    }

    location / { return 404; }
}
NGINX

nginx -t
systemctl daemon-reload
systemctl enable --now ghanizada-websockify
systemctl enable --now nginx
systemctl restart nginx

if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -q active; then
  ufw allow "${LISTEN_PORT}/tcp" >/dev/null || true
fi

echo
echo "=============================================="
echo " GHANIZADA VPS SSH WEBSOCKET BRIDGE READY"
echo "=============================================="
echo "Listen : 0.0.0.0:${LISTEN_PORT}${WS_PATH}"
echo "Target : 127.0.0.1:22"
echo "Service: ghanizada-websockify"
echo "Nginx  : active"
echo "=============================================="
echo "Use the Cloud Run hostname as the client host."
echo "Do not disable or replace SSH port 22."
