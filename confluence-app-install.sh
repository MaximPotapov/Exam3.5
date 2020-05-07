#!/bin/bash

sudo apt-get install mysql-server
Q1="CREATE DATABASE IF NOT EXISTS confdb;"
Q2="GRANT ALL ON *.* TO '$confuser'@'%' IDENTIFIED BY 'ConfPassword';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
mysql -uroot -pRootPassword -h192.168.56.103 -e "$SQL"
ok() { echo -e '\e[32m'$1'\e[m'; }
ok "Database confdb and user confuser created with a password ConfPassword"

sudo su -

apt install -y nginx
sudo openssl req -newkey rsa:4096 \
            -x509 \
            -sha256 \
            -days 3650 \
            -nodes \
            -out /etc/nginx/app.crt \
            -keyout /etc/nginx/app.key \
            -subj "/C=GB/ST=ENGLAND/L=LIVERPOOL/O=Security/OU=IT Department/CN=app"

cat << EOF >> "/etc/nginx/conf.d/proxy.ssl.conf"
server {
listen       192.168.56.102:443 ssl http2;
keepalive_timeout 10;
send_timeout 10;
server_tokens off;


server_name app;


ssl_session_timeout  20m;
ssl_certificate /etc/nginx/app.crt;
ssl_certificate_key /etc/nginx/app.key;
ssl_protocols TLSv1.2; # don’t use SSLv3 ref: POODLE
ssl_ciphers HIGH:!aNULL:!CAMELLIA:!SHA:!RSA;
ssl_prefer_server_ciphers   on;
ssl_session_tickets off;
client_body_timeout 10;
client_header_timeout 10;
client_max_body_size 10m;
client_body_buffer_size 10m;


location / {
    proxy_pass http://127.0.0.1:8090;
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
        proxy_pass http://127.0.0.1:8091/synchrony;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "Upgrade";
    }

 error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}

EOF

 sudo nano /etc/mysql/my.cnf 
  echo "[mysqld]
        character-set-server=utf8mb4
        collation-server=utf8mb4_bin
        default-storage-engine=INNODB
        max_allowed_packet=256M
        innodb_log_file_size=2GB
        transaction-isolation=READ-COMMITTED
        binlog_format=row"

sudo service mysql restart
sudo service mysql start
systemctl enable nginx && nginx -t && systemctl start nginx
sudo /etc/init.d/confluence start

cd /opt
wget https://downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-6.2.0-x64.bin
chmod 755 atlassian-confluence-6.2.0-x64.bin
./atlassian-confluence-6.2.0-x64.bin -q
wget https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.20/mysql-connector-java-8.0.20.jar
cp ./mysql-connector-java-8.0.20.jar /opt/Confluence/lib/