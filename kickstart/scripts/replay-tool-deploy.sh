#!/bin/bash

dst=/opt/replay-tool

# Ubuntu-specific deployment
deploy_replay_tool_ubuntu() {
    mkdir -p "$dst"
    chmod 755 "$dst"

    # Clone server and client
    git clone https://github.com/posm/posm-replay-server "$dst"
    git clone https://github.com/posm/posm-replay-client "$dst"

    # install yarn
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

    sudo apt update && sudo apt install yarn

    cd "$dst/posm-replay-client" && yarn install && yarn build

    # Copy env vars for server
    cp "$dst/posm-replay-server/env_sample" "$dst/posm-replay-server/.env"

}

deploy replay_tool
