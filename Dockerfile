FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    gettext \
    nginx \
    python3 \
    python3-dev \
    python3-setuptools \
    python-setuptools \
    python-is-python3 \
    uwsgi \
    uwsgi-plugin-python3 \
    virtualenv \
    python3-virtualenv \
    python3-pip \
    python3-yaml \
    postgresql-client \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /var/log/bounca && chown -R www-data:www-data /var/log/bounca && chmod 0770 /var/log/bounca

RUN mkdir -p /srv/www/ &&\
    cd /srv/www &&\ 
    curl -o bounca.tar.gz https://gitlab.com/bounca/bounca/-/package_files/76149910/download &&\
    tar -zxvf bounca.tar.gz &&\
    rm -rf bounca.tar.gz &&\
    chown www-data:www-data -R /srv/www/bounca 

RUN cp /srv/www/bounca/etc/uwsgi/bounca.ini /etc/uwsgi/apps-available/bounca.ini &&\
    ln -s /etc/uwsgi/apps-available/bounca.ini /etc/uwsgi/apps-enabled/bounca.ini &&\
    mkdir /etc/bounca &&\
    mkdir -p /var/run/uwsgi/app/bounca &&\
    mkdir /ssl &&\
    mkdir /nginx_conf &&\
    cp /srv/www/bounca/etc/bounca/services.yaml.example /etc/bounca/services.yaml

RUN cd /srv/www/bounca && virtualenv env -p python3 && /srv/www/bounca/env/bin/pip install -r requirements.txt

ENV DB_NAME=""
ENV DB_USER=""
ENV DB_PASSWORD=""
ENV DB_HOST=""
ENV DB_PORT="5432"
ENV MAIL_HOST=""
ENV MAIL_PORT=""
ENV MAIL_USER=""
ENV MAIL_PASSWORD=""
ENV MAIL_CONNECTION=""
ENV MAIL_ADMIN=""
ENV MAIL_FROM=""
ENV CE_KEY_ALGO=""
ENV EMAIL_VERIFICATION=""
ENV DOMAIN=""

VOLUME "/etc/bounca" 
VOLUME "/ssl"

COPY configure.py /configure.py
COPY entrypoint.sh /entrypoint.sh
COPY config/supervisord.conf /etc/supervisor/supervisord.conf

RUN chmod +rwx /entrypoint.sh

ADD config/bounca-withoutssl.conf config/bounca-withssl-redirect.conf config/bounca-withssl.conf /nginx_conf/

EXPOSE 80/tcp
EXPOSE 443/tcp

CMD /entrypoint.sh
