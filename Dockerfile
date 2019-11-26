FROM php:5.6.40-fpm-alpine

ENV PHPREDIS_VERSION 3.1.2

RUN apk add -U tzdata \
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apk del tzdata \
    && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk update \
    && apk add nginx \
    && apk add supervisor

#安装php扩展包
RUN apk add php5-fpm php5-mcrypt php5-soap php5-openssl php5-gmp php5-pdo_odbc php5-json php5-dom php5-pdo php5-zip php5-mysql php5-mysqli php5-sqlite3 php5-apcu php5-pdo_pgsql php5-bcmath php5-gd  php5-odbc php5-pdo_mysql php5-pdo_sqlite php5-gettext php5-xmlreader php5-xmlrpc php5-bz2  php5-mssql php5-iconv php5-pdo_dblib php5-curl php5-ctype \
    && curl -L -o /tmp/redis.tar.gz https://github.com/phpredis/phpredis/archive/$PHPREDIS_VERSION.tar.gz \
    && tar xfz /tmp/redis.tar.gz \
    && rm -r /tmp/redis.tar.gz \
    && mkdir -p /usr/src/php/ext \
    && mv phpredis-$PHPREDIS_VERSION /usr/src/php/ext/redis \
    && docker-php-ext-install redis \
    && rm -rf /usr/src/php 

#调整php.ini配置参数
RUN sed  -i '235i\output_buffering = on' /etc/php5/php.ini \
    && sed  -i 's/disable_functions =/disable_functions = system,chroot,chgrp,chown,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket/g' /etc/php5/php.ini \
    && sed  -i 's/expose_php = on/expose_php = off/g' /etc/php5/php.ini \ 
    && sed  -i 's/max_execution_time = 30/max_execution_time = 300/g'  /etc/php5/php.ini \
    && sed  -i 's/; max_input_vars = 1000/max_input_vars = 3000/g' /etc/php5/php.ini \
    && sed  -i 's/request_order = "GP"/request_order = "CGP"/g' /etc/php5/php.ini \
    && sed  -i 's/post_max_size = 8M/post_max_size = 50M/g' /etc/php5/php.ini \
    && sed  -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' /etc/php5/php.ini \
    && sed  -i 's/upload_max_filesize = 2M/upload_max_filesize = 50M/g' /etc/php5/php.ini \
    && sed  -i '825i\upload_tmp_dir = \/tmp' /etc/php5/php.ini \
    && sed  -i 's/date.timezone = UTC/date.timezone = Asia\/Shanghai/g' /etc/php5/php.ini \
    && sed  -i 's/;sendmail_path =/sendmail_path = \/usr\/sbin\/sendmail -t -i/g' /etc/php5/php.ini \
    && sed  -i 's/mysqlnd.collect_memory_statistics = off/mysqlnd.collect_memory_statistics = on/g'  /etc/php5/php.ini \
    && sed  -i 's/session.cookie_httponly =/session.cookie_httponly = 1/g'   /etc/php5/php.ini \
    && echo "extension=\"/usr/local/lib/php/extensions/no-debug-non-zts-20131226/redis.so\"" >> /etc/php5/php.ini

    
#调整nginx 配置参数
RUN touch /var/run/nginx.pid \
    && sed -i 's/user nginx;/user www-data;/g' /etc/nginx/nginx.conf \
    && sed -i '4i\pid /var/run/nginx.pid;' /etc/nginx/nginx.conf \
    && sed -i 's/client_max_body_size 1m;/client_max_body_size 20m;/g' /etc/nginx/nginx.conf \
    && sed -i 's/#tcp_nopush on;/tcp_nopush on;/g' /etc/nginx/nginx.conf \
    && sed -i '78i\	server_names_hash_bucket_size 128;' /etc/nginx/nginx.conf \
    && sed -i '79i\	client_header_buffer_size 32k;' /etc/nginx/nginx.conf \
    && sed -i '80i\	large_client_header_buffers 4 32k;' /etc/nginx/nginx.conf \
    && sed -i '81i\	client_body_buffer_size 256k;' /etc/nginx/nginx.conf \
    && sed -i '83i\	fastcgi_connect_timeout 300;' /etc/nginx/nginx.conf \
    && sed -i '84i\	fastcgi_send_timeout 300;' /etc/nginx/nginx.conf \
    && sed -i '85i\	fastcgi_read_timeout 300;' /etc/nginx/nginx.conf \
    && sed -i '86i\	fastcgi_buffer_size 128k;' /etc/nginx/nginx.conf \
    && sed -i '87i\	fastcgi_buffers 32 256k;' /etc/nginx/nginx.conf \
    && sed -i '88i\	fastcgi_busy_buffers_size 256k;' /etc/nginx/nginx.conf \
    && sed -i '89i\	fastcgi_temp_file_write_size 256k;' /etc/nginx/nginx.conf \
    && echo "daemon off;" >> /etc/nginx/nginx.conf

#调整supervisor 配置参数
RUN mkdir /etc/supervisor.d \
    && sed -i 's/;nodaemon=false/nodaemon=true/g' /etc/supervisord.conf \
    && sed -i 's/;pidfile=/pidfile=/g' /etc/supervisord.conf \
    && sed -i 's/files\ \=\ \/etc\/supervisor.d\/\*\.ini/files\ \=\ \/docker\/supervisor\/\*\.conf/g' /etc/supervisord.conf

RUN sed -i 's/;daemonize\s*=\s*yes/daemonize = no/g' /etc/php5/php-fpm.conf \
    && sed -i 's/127.0.0.1:9000/\/run\/php\/php5.6-fpm.sock/g' /etc/php5/php-fpm.conf \
    && sed -i 's/user = nobody/user = www-data/g' /etc/php5/php-fpm.conf \
    && sed -i 's/group = nobody/group = www-data/g' /etc/php5/php-fpm.conf \
    && sed -i 's/listen.owner = nobody/listen.owner = www-data/g'  /etc/php5/php-fpm.conf \
    && sed -i 's/listen.group = nobody/listen.group = www-data/g'  /etc/php5/php-fpm.conf \
    && mkdir /run/php/

WORKDIR /root

