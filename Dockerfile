FROM ubuntu:bionic

RUN mkdir /app
WORKDIR /app
COPY ./snap-cloud-beta-0.rockspec /app

# Install wget because the base docker is very slim...
RUN apt-get update; \
    apt-get install -y wget gnupg software-properties-common \
         libssl-dev lua5.1 openssl luarocks git
    # rm -rf /var/lib/apt/lists/*
# Add openresty key
# TODO could just inline this file.
RUN wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN add-apt-repository -y "deb http://openresty.org/package/ubuntu bionic main"
RUN apt-get update; \
    apt-get install -y --no-install-recommends openresty; \
    rm -rf /var/lib/apt/lists/*
RUN luarocks install snap-cloud-beta-0.rockspec
# RUN curl -sS -L -O https://github.com/nginxinc/nginx-amplify-agent/raw/master/packages/install.sh &&  API_KEY='YOUR_API_KEY' sh ./install.sh
# RUN install certbot

COPY ./ /app

# TODO: How do we handle dev vs prod?
EXPOSE 80
EXPOSE 8080

# TODO Enviornment variables?
# ENV NAME value

# Start the app
# CMD ["lapis", "serve"]
CMD ["bash"]
# TASKS
# * install snapcloud daemon (do that matter?)
# * figure out logging + config hooks
