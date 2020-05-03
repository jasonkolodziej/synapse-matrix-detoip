source '.env'
N1=nginx.init.conf
N2=nginx.conf
_remote_addr='$remote_addr'
_remote_user='$remote_user'
_time_local='$time_local'
_request='$request'
_host='$host'
_request_uri='$request_uri'
_status='$status'
_body_bytes_sent='$body_bytes_sent'
_http_referer='$http_referer'
_http_user_agent='$http_user_agent' 
_http_x_forwarded_for='$http_x_forwarded_for'
_proxy_add_x_forwarded_for='$proxy_add_x_forwarded_for'
_scheme='$scheme'
_one='$1'
echo "Creating $N1 file..."
{
cat <<-EOF >> $N1

user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
  worker_connections  1024;
}

http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  log_format  main  '$_remote_addr - $_remote_user [$_time_local] "$_request" '
                    '$_status $_body_bytes_sent "$_http_referer" '
                    '"$_http_user_agent" "$_http_x_forwarded_for"';

  access_log  /var/log/nginx/access.log  main;
  sendfile     on;
  tcp_nopush   on;
  server_names_hash_bucket_size 128; # this seems to be required for some vhosts

  server {
    listen      80;
    listen [::]:80;
    server_name ${FQDN};

    location / {
        rewrite ^ https://$_host$_request_uri? permanent;
    }

    location ^~ /.well-known {
        allow all;
        root  /data/letsencrypt/;
    }
  }
}
EOF
}&> /dev/null

echo "Creating $N2 file..."
{
cat <<-EOF >> $N2

user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
  worker_connections  1024;
}


http {
  include       /etc/nginx/mime.types;
  default_type  application/octet-stream;

  log_format  main  '$_remote_addr - $_remote_user [$_time_local] "$_request" '
                    '$_status $_body_bytes_sent "$_http_referer" '
                    '"$_http_user_agent" "$_http_x_forwarded_for"';

  access_log  /var/log/nginx/access.log  main;
  sendfile     on;
  tcp_nopush   on;
  server_names_hash_bucket_size 128; # this seems to be required for some vhosts

  server {
    listen      80;
    listen [::]:80;
    server_name ${FQDN};

    location / {
        rewrite ^ https://$_host$_request_uri? permanent;
    }

    location ^~ /.well-known {
        allow all;
        root  /data/letsencrypt/;
    }
  }

  # `${FQDN}` was originally example.com
  server { # simple reverse-proxy
    listen       443 ssl;

    ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
    ssl_trusted_certificate   /etc/letsencrypt/live/${FQDN}/chain.pem;

    server_name ${FQDN};

    access_log                /dev/stdout;
    error_log                 /dev/stderr info;
    client_max_body_size  512m;

    # pass requests for dynamic content to rails/turbogears/zope, et al
    # see : https://www.natrius.eu/dokuwiki/doku.php?id=digital:server:matrixsynapse
    location / {
      proxy_set_header        Host $_host;
      proxy_set_header        X-Real-IP $_remote_addr;
      proxy_set_header        X-Forwarded-For $_proxy_add_x_forwarded_for;
      proxy_set_header        X-Forwarded-Proto $_scheme;

      proxy_pass          http://synapse:8008;
      proxy_read_timeout  90;

      proxy_redirect      http://synapse:8008 https://${FQDN};
    }

    #for synapse delegation
    # `${FQDN}` was originally matrix.example.com
    location ~ ^/.well-known/matrix/server$ {
      return 200 '{"m.server": "${FQDN}:443"}';
      add_header Content-Type application/json;
    }
    location ~ ^/.well-known/matrix/client$ {
      return 200 '{"m.homeserver": {"base_url": "https://${FQDN}"},"m.identity_server": {"base_url": "https://vector.im"}}';
      add_header Content-Type application/json;
      add_header "Access-Control-Allow-Origin" *;
    }

    # location /riot/ {
    #   proxy_set_header        Host $_host;
    #   proxy_set_header        X-Real-IP $_remote_addr;
    #   proxy_set_header        X-Forwarded-For $_proxy_add_x_forwarded_for;
    #   proxy_set_header        X-Forwarded-Proto $_scheme;

    #   rewrite ^/riot(/.*)$ $_one break;

    #   proxy_pass          http://riotweb:80;
    #   proxy_read_timeout  90;

    #   proxy_redirect      off;
    # }
  }

  # for federation purposes
  server {
    listen 8448 ssl;
    ssl_certificate /etc/letsencrypt/live/${FQDN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FQDN}/privkey.pem;
    ssl_trusted_certificate   /etc/letsencrypt/live/${FQDN}/chain.pem;

    server_name ${FQDN};

    location / {
        proxy_pass http://synapse:8008;
        proxy_set_header X-Forwarded-For $_remote_addr;
    }

}

}
EOF
}&> /dev/null

echo "WARNING: Please check the '$N1' & '$N2' file(s) created before continuing..."