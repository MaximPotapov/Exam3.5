#!/bin/bash

sudo yum -y install epel-release
sudo yum -y install nginx
sudo openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -out /etc/nginx/proxy.crt \
            -keyout /etc/nginx/proxy.key \
            -subj "/C=GB/ST=ENGLAND/L=LIVERPOOL/O=Security/OU=IT Department/CN=proxy"

sudo su -
cat << EOF >> "/etc/nginx/conf.d/proxy.ssl.conf"
server {
listen       192.168.56.101:443 ssl http2;
keepalive_timeout 10;
send_timeout 10;
server_tokens off;


server_name proxy;


ssl_session_timeout  20m;
ssl_certificate /etc/nginx/proxy.crt;
ssl_certificate_key /etc/nginx/proxy.key;
ssl_protocols TLSv1.2; # don’t use SSLv3 ref: POODLE
ssl_ciphers HIGH:!aNULL:!CAMELLIA:!SHA:!RSA;
ssl_prefer_server_ciphers   on;
ssl_session_tickets off;
client_body_timeout 10;
client_header_timeout 10;
client_max_body_size 10m;
client_body_buffer_size 10m;

access_log  /var/log/nginx/access_proxy.ssl.log  main;
error_log  /var/log/nginx/error_proxy.ssl.log  info;


location / {
    proxy_pass https://192.168.56.102;
    proxy_redirect off;
    proxy_set_header Host \$http_host;
    proxy_set_header X-NginX-Proxy true;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto https;
    port_in_redirect off;
    proxy_connect_timeout 600;
            }

location /synchrony {
        proxy_set_header X-Forwarded-Host \$host;
        proxy_set_header X-Forwarded-Server \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_pass http://192.168.56.102:8091/synchrony;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection Upgrade;
    }

 error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
} 

EOF
 nano /etc/nginx/nginx.conf

echo "<html>
    <head>
        <title>PROXY</title>
    </head>
    <body>
        <h1 style="font-size: 64">Welcome to the club buddy!</h1>
    </body>
</html>" > /usr/share/nginx/html/index.html

systemctl enable nginx && nginx -t && systemctl start nginx