#!/bin/bash
SSL_ENABLED=0
SSL_CHAIN_PATH=""
SSL_KEY_PATH=""

if [ -f "/ssl/$DOMAIN-chain.pem" ] && [ -f "/ssl/$DOMAIN.key" ]; then
    SSL_ENABLED=1
    SSL_CHAIN_PATH="/ssl/$DOMAIN-chain.pem"
    SSL_KEY_PATH="/ssl/$DOMAIN.key"
fi

if [ $SSL_ENABLED -eq 1 ]; then 
    cp /nginx_conf/bounca-withssl.conf /etc/nginx/sites-available/bounca-ssl.conf
    cp /nginx_conf/bounca-withssl-redirect.conf /etc/nginx/sites-available/bounca.conf

    ln -s /etc/nginx/sites-available/bounca-ssl.conf /etc/nginx/sites-enabled/bounca-ssl.conf
    ln -s /etc/nginx/sites-available/bounca.conf /etc/nginx/sites-enabled/bounca.conf

    sed -i "s/ssl_certificate <<SSL_PEM>>;/ssl_certificate $SSL_CHAIN_PATH;/" /etc/nginx/sites-available/bounca-ssl.conf
    sed -i "s/ssl_certificate_key <<SSL_KEY>>;/ssl_certificate_key $SSL_KEY_PATH;/" /etc/nginx/sites-available/bounca.conf
else
    cp /nginx_conf/bounca-withoutssl.conf /etc/nginx/sites-available/bounca.conf
    ln -s /etc/nginx/sites-available/bounca.conf /etc/nginx/sites-enabled/bounca.conf
fi

pg_isready --host=$DB_HOST --port=$DB_PORT --username=$DB_USER

if [ $? -eq 0 ]; then
    python3 /configure.py
    sed -i "s/server_name <<DOMAIN>>;/server_name $DOMAIN;/" /etc/nginx/sites-available/bounca.conf

    sudo -u www-data cd /srv/www/bounca && env/bin/python3 manage.py migrate
    sudo -u www-data cd /srv/www/bounca && echo "yes" | env/bin/python3 manage.py collectstatic --clear
    sudo -u www-data cd /srv/www/bounca && env/bin/python3 python3 manage.py site $DOMAIN
    exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
else
    echo "Cannot connect to PostgreSQL"
fi
