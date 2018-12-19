# Base Ubuntu 18.04 w/ compiled OpenResty
FROM openresty/openresty:bionic

RUN mkdir /app
COPY ./snap-cloud-beta-0.rockspec /app
RUN luarocks install snapcloud-beta-0
# RUN curl -sS -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh &&  API_KEY='YOUR_API_KEY' sh ./install.sh
# RUN install certbot

COPY ./ /app
WORKDIR /app

# TASKS
# * install daemon (do that matter?)
# * figure out logging + config hooks