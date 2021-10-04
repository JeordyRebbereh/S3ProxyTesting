#
# This is an image to use in CircleCI to build Docker images and push them to AWS or Heroku.
# It also contains commands useful for deploying non-Docker content, such as s4cmd to push to S3 buckets, as well
# as things CircleCI needs, like git and openssh-client.
#

FROM alpine:3.14

# Adapted from https://github.com/coopernurse/nginx-s3-proxy/blob/master/Dockerfile
RUN apk add --no-cache -t .build ruby-dev build-base g++ openssl-dev pcre-dev zlib-dev
RUN apk add --no-cache -t curl git bash python3
RUN ln -s /usr/bin/python3 /usr/bin/python
RUN apk add --no-cache -t .nginx openssl pcre zlib
RUN curl -L -o - http://nginx.org/download/nginx-1.19.4.tar.gz | tar xzf -
RUN cd nginx-* \
    && git clone https://github.com/anomalizer/ngx_aws_auth.git \
    && (cd ngx_aws_auth ; git checkout 21931b2 ) \
    && ./configure --with-http_ssl_module --add-module=ngx_aws_auth \
    && make -j2 install \
    && install -m 0755 ngx_aws_auth/generate_signing_key /usr/local/bin
RUN cd ..
    && rm -rf nginx-* \
    && apk del --no-cache .build

COPY start-s3-proxy.sh /usr/local/bin/

CMD ["/bin/bash", "/usr/local/bin/start-s3-proxy.sh", "jeordy-test-bucket", "us-east-2"]
