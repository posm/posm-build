#!/bin/bash

dst=/opt/posm-auth

# Ubuntu-specific deployment
deploy_posm_auth_ubuntu() {
    mkdir -p "$dst"
    chmod 755 "$dst"

    # Install docker compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.25.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Clone posm auth
    git clone https://github.com/posm/posm-auth $dst

    # Copy env vars for server if sample file exists
    touch "$dst/.env"
    if [[ -f $dst/env_sample ]]; then
        cp "$dst/env_sample" "$dst/.env"
    fi

    # Expand and copy nginx confs and include files
    expand etc/nginx-posm-auth.conf /etc/nginx/sites-available/posm-auth
    expand etc/nginx-posm-auth.include /etc/nginx/sites-available/posm-auth.include
    ln -s -f ../sites-available/posm-auth.include /etc/nginx/sites-enabled/
    ln -s -f ../sites-available/posm-auth /etc/nginx/sites-enabled/

    # Copy html and static files for error pages
    mkdir -p $dst/assets/images
    cp etc/posm_auth/assets/images/* $dst/assets/images/
    # Expand the html files which contain {{auth_base_url}}
    expand etc/posm-auth/assets/403.html $dst/assets/
    expand etc/posm-auth/assets/404.html $dst/assets/

    # copy systemd unit into place, replacing template variables in the process
    expand etc/systemd/system/posm-auth.service.hbs /etc/systemd/system/posm-auth.service

    # Enable replay-tool.service
    systemctl enable --now posm-auth.service

    # Run replay-tool service
    systemctl start posm-auth.service
}

deploy posm_auth
