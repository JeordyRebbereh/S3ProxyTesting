#!/bin/bash

if [[ -z "$2" ]]; then
    echo "usage: $0 <bucket> <region>" >&2
    exit 1
fi

BUCKET=$1
AWS_REGION=$2
SIG=( $(generate_signing_key -k ${AWS_SECRET_ACCESS_KEY} -r ${AWS_REGION}) )
S3_SIGNING_KEY=${SIG[0]}
S3_SIGNING_KEY_SCOPE=${SIG[1]}

cat > /var/tmp/nginx.conf.$$ <<EOF
worker_processes 2;
pid /var/run/nginx.pid;
daemon off;

events {
    worker_connections 768;
}

http {
    include /usr/local/nginx/conf/mime.types;
    default_type application/octet-stream;

    access_log /dev/stdout;
    error_log  /dev/stderr;

    server {
        listen     8000;

        location / {
            aws_sign;
            aws_access_key ${AWS_ACCESS_KEY_ID};
            aws_signing_key ${S3_SIGNING_KEY};
            aws_key_scope ${S3_SIGNING_KEY_SCOPE};
            aws_endpoint s3.${AWS_REGION}.amazonaws.com;
            aws_s3_bucket ${BUCKET};
            proxy_pass https://${BUCKET}.s3.${AWS_REGION}.amazonaws.com/;
        }
    }
}
EOF

exec /usr/local/nginx/sbin/nginx -c /var/tmp/nginx.conf.$$