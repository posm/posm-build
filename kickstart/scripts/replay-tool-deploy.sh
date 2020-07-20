#!/bin/bash

dst=/opt/replay-tool
server_path=$dst/posm-replay-server
client_path=$dst/posm-replay-client

deploy_server() {
    mkdir -p "$dst"
    chmod 755 "$dst"

    # Install docker compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Clone server
    git clone https://github.com/posm/posm-replay-server "$dst/posm-replay-server"

    # Copy env vars for server
    cp "$dst/posm-replay-server/env_sample" "$server_path/.env"

    expand etc/nginx-replay-tool.conf /etc/nginx/sites-available/replay-tool
    ln -s -f ../sites-available/replay-tool /etc/nginx/sites-enabled/

    # copy systemd unit into place, replacing template variables in the process
    expand etc/systemd/system/replay-tool.service.hbs /etc/systemd/system/replay-tool.service

    # Enable replay-tool.service
    systemctl enable --now replay-tool.service

    # Run replay-tool service
    systemctl start replay-tool.service
}

deploy_client() {
    mkdir -p "$dst"
    mkdir -p "$client_path"
    chmod 755 "$dst"

    rm -rf "$client_path/*" 2> /dev/null

    # Clone client
    git clone https://github.com/posm/posm-replay-client "$client_path"
    Copy environment variables
    cp "$dst/posm-replay-client/env_sample" "$client_path/.env"

    cd $client_path && docker run --rm -it -v $(pwd):/code node:8.16.0-alpine sh -c 'apk add git && cd code && yarn install && yarn build'

    chown www-data:www-data "$client_path" -R
}

# Ubuntu-specific deployment
deploy_replay_tool_ubuntu() {
    deploy_client
    deploy_server
}

deploy_replay_tool_ubuntu

# deploy replay_tool
