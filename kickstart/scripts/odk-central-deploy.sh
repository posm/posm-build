#!/bin/bash -e

dst=/opt/odk-central
repo_path=$dst/odk-central-repo
build_path=$dst/client-build
odk_central_release_tag='posm'

# Ubuntu-specific deployment
deploy_odk_central_ubuntu() {
    mkdir -p "$dst"
    chmod 755 "$dst"

    # Clone ODK central
    git clone https://github.com/posm/central --branch $odk_central_release_tag $repo_path
    cd $repo_path
    git submodule update -i  # git pull ODK client and server

    # Build Docker Images (Using custom docker-compose.yml)
    expand etc/odk-central-docker-compose.yml $repo_path/docker-compose.yml
    docker-compose build

    # Copy Client Build
    docker-compose run --rm \
        --volume="$build_path:/host-client-build/" \
        --entrypoint="cp -vr /usr/share/nginx/html/. /host-client-build/" nginx
    chown www-data:www-data "$build_path" -R

    # Create containers for odk-central and initial user with admin access
    docker-compose up service -d
    docker-compose exec service bash -c "
        npm install -g wait-port && wait-port 8383 && odk-cmd --email $odk_central_user user-create --password $odk_central_password"
    docker-compose exec service odk-cmd --email $odk_central_user user-promote
    docker-compose stop

    # Enable and run odk-central.service
    expand etc/systemd/system/odk-central.service.hbs /etc/systemd/system/odk-central.service
    systemctl enable --now odk-central.service

    # Copy and enable nginx configuration
    expand etc/nginx-odk-central.conf /etc/nginx/sites-available/odk-central
    ln -s -f ../sites-available/odk-central /etc/nginx/sites-enabled/
}

deploy odk_central
