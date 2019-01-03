# Snap!Cloud Dockerfile
# This has the basics needed for deployments, and running in development.
# For development, this should be run with docker compose.
FROM ubuntu:bionic
MAINTAINER Michael Ball <ball@berkeley.edu>

RUN mkdir /app
WORKDIR /app
COPY ./snap-cloud-beta-0.rockspec /app

# Install base system dependencies
# libssl-dev has the headers needed for luacrypto
RUN apt-get update; \
    apt-get install -y wget gnupg software-properties-common \
         libssl-dev lua5.1 openssl luarocks git
RUN wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN add-apt-repository -y "deb http://openresty.org/package/ubuntu bionic main"
RUN apt-get update; \
    apt-get install -y --no-install-recommends openresty; \
    rm -rf /var/lib/apt/lists/*
RUN luarocks install snap-cloud-beta-0.rockspec
# RUN curl -sS -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh &&  API_KEY='YOUR_API_KEY' sh ./install.sh
# RUN install certbot

COPY ./ /app

EXPOSE 80
# EXPOSE 8080

# TODO Enviornment variables?
# ENV NAME value

# Start the app
# CMD ["lapis", "server"]
# CMD ["bash"]
# TASKS
# * install snapcloud daemon (do that matter?)
# * figure out logging + config hooks
