#!/bin/bash

VPS_IP=""
VPS_USERNAME=""
VPS_PASSWORD=""
VPS_PORT=""
VPS_DOMAIN=""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        IP)
        VPS_IP="$2"
        shift
        shift
        ;;
        USERNAME)
        VPS_USERNAME="$2"
        shift
        shift
        ;;
        PASSWORD)
        VPS_PASSWORD="$2"
        shift
        shift
        ;;
        PORT)
        VPS_PORT="$2"
        shift
        shift
        ;;
        DOMAIN)
        VPS_DOMAIN="$2"
        shift
        shift
        ;;
        *)
        echo "Error: Invalid argument '$key'. Valid arguments are IP, USERNAME, PASSWORD, PORT, and DOMAIN."
        exit 1
        ;;
    esac
done

if [[ -z $VPS_IP || -z $VPS_USERNAME || -z $VPS_PASSWORD || -z $VPS_PORT || -z $VPS_DOMAIN ]]; then
    echo "Error: Missing one or more required arguments (IP, USERNAME, PASSWORD, PORT, or DOMAIN)."
    exit 1
fi

sshpass -p "$VPS_PASSWORD" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$VPS_PORT" "$VPS_USERNAME@$VPS_IP" << EOF

locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8
apt update -y && apt install nginx vim rsync net-tools curl wget jq vnstat htop sshpass -y
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
systemctl enable v2ray && systemctl enable nginx

cd /root/

git clone https://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@github.com/WeAreCrazyEnoughToDie/lhsconfigfiles.git

mv lhsconfigfiles/config.json /usr/local/etc/v2ray/config.json
mv lhsconfigfiles/server /root/ && chmod +x server
mv lhsconfigfiles/.env /root/
mv lhsconfigfiles/web.service /lib/systemd/system/web.service
rm -rf /root/lhsconfigfiles

nginx_CONF='server {
    listen 80;
    listen [::]:80;
    server_name *.${VPS_DOMAIN};
    charset utf-8;

}

server {
    listen       443 ssl http2;
    listen       [::]:443 ssl http2;
    server_name  *.${VPS_DOMAIN};
    charset utf-8;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache builtin:1000 shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_buffer_size 1400;
    ssl_session_tickets off;
    ssl_certificate /root/cert/fullchain.pem;
    ssl_certificate_key /root/cert/private.key;

    root /usr/share/nginx/html;

    location /ws {
      proxy_redirect off;
      proxy_pass http://127.0.0.1:10001;
      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host \$host;
      # Show real IP in v2ray access.log
      proxy_set_header X-Real-IP \$remote_addr;
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}'

echo "${nginx_CONF}" >/etc/nginx/conf.d/${VPS_DOMAIN}.conf

v2ray_Service='[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/v2ray run -config /usr/local/etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
}'

echo "${v2ray_Service}" >/etc/systemd/system/v2ray.service
mkdir /var/log/webs
systemctl daemon-reload && systemctl restart v2ray && systemctl enable web.service && systemctl start web.service && systemctl restart nginx
EOF

echo "Install Done!"
