#!/bin/bash

clear
echo "====================================="
echo "        Powered By Shadow"
echo "====================================="
sleep 1


if [[ $EUID -ne 0 ]]; then
   echo "❌ Please run as root!"
   exit 1
fi

apt update -y
apt upgrade -y
apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg unzip git
LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php

apt install -y nginx mariadb-server mariadb-client redis-server tar unzip git \
php8.2 php8.2-cli php8.2-gd php8.2-mysql php8.2-pdo php8.2-mbstring \
php8.2-tokenizer php8.2-bcmath php8.2-xml php8.2-curl php8.2-zip composer

mysql_secure_installation

cd /var/www/
mkdir -p nebula
cd nebula

curl -Lo nebula.tar.gz https://github.com/Nebula-Panel/panel/releases/latest/download/panel.tar.gz
tar -xzvf nebula.tar.gz
chmod -R 755 storage/* bootstrap/cache/
cp .env.example .env
composer install --no-dev --optimize-autoloader
php artisan key:generate --force

cat <<EOF > /etc/nginx/sites-available/nebula.conf
server {
    listen 80;
    server_name _;
    root /var/www/nebula/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php;
    }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

ln -s /etc/nginx/sites-available/nebula.conf /etc/nginx/sites-enabled/
systemctl restart nginx
systemctl enable nginx redis mariadb

echo
echo "====================================="
echo " Nebula Installation Completed"
echo " Powered By Shadow"
echo "====================================="
