#!/bin/sh
: ${TARGET_SERVER:?}
: ${DNS_NAME:?}
confpath=/etc/nginx/nginx.conf
cat << EOF > $confpath

worker_processes 1;

events { worker_connections 1024; }

http {

    sendfile on;

    upstream target-server {
        server $TARGET_SERVER;
    }

    limit_req_zone \$binary_remote_addr zone=mylimit:10m rate=5r/s;

    # default server to catch unmatching requests, and reject them!
    server {
        listen 80;
        return 404;
    }

    server {
        listen 80;
        server_name $DNS_NAME
                    localhost
                    ;

        location ~ \.php {
            deny all;
        }

        location / {
            limit_req zone=mylimit burst=20 nodelay;
            proxy_pass         http://target-server;
            proxy_redirect     off;
            proxy_set_header   Host \$host;
            proxy_set_header   X-Real-IP \$remote_addr;
            proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header   X-Forwarded-Host \$server_name;

            limit_except GET {
                deny all;
            }
        }
    }
}
EOF

echo '[INFO] using nginx.conf'
cat $confpath

nginx -g "daemon off;"
