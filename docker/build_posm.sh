#!/bin/bash

# This temp directory MUST be inside the Docker build context (e.g. current directory).
TMP_DIR=$(pwd)/tmp

DOCKER_HUB_ADDR=https://index.docker.io/v1/

POSM_NET_NAME=posm-net

# Note that since PGSQL_VER is concatenated to various module names in the OSM dockerfile, we can only use major versions.
PGSQL_VER=12
POSTGIS_VER=3
PG_DOCKER_TAG=posm/posm-pg:0.1
PG_CONTAINER_NAME=posm-pg
PG_DATA_DIR=/Users/cvonsee/temp/pg_data
PG_ADMIN_USER=postgres
PG_ADMIN_PASSWORD=openstreetmap

OSM_DOCKER_TAG=posm/posm-osm:0.1
OSM_CONTAINER_NAME=posm-osm

osm_pg_owner="openstreetmap"
osm_pg_pass="openstreetmap"
osm_pg_dbname="openstreetmap"

osm_carto_pg_dbname="gis"
osm_carto_pg_temp_dbname="gis_temp"
osm_carto_pg_owner="gis"
osm_carto_pg_users="root fp omk"
osm_carto_pg_pass="openstreetmap"

# ============================================
# GENERAL SETUP
# ============================================
mkdir -p $TMP_DIR
mkdir -p $PG_DATA_DIR

git clone https://github.com/posm/posm-build $TMP_DIR/posm-build


#
# Log in to Docker Hub.  Note that this requires DOCKER_HUB_USERID and DOCKER_HUB_PASSWORD environment variables 
# to be declared prior to running this script.  
# TODO Set up to use credentials store as per https://docs.docker.com/engine/reference/commandline/login/#credentials-store
#
docker login \
        --username $DOCKER_HUB_USERID \
        --password $DOCKER_HUB_PASSWORD \
        $DOCKER_HUB_ADDR

# ============================================
# CREATE DOCKER NETWORK (This config is for a bridge network and requires all containers to be on the same host)
# ============================================
docker network create -d bridge $POSM_NET_NAME

# ============================================
# CREATE POSTGRES
# ============================================
#
# Build Postgres image
# 
docker build \
        --file ./dockerfile-postgres12 \
        --build-arg PGSQL_VER=$PGSQL_VER \
        --build-arg POSTGIS_VER=$POSTGIS_VER \
        --tag $PG_DOCKER_TAG \
        .

# Start Postgres.  This needs to be running so that other components can connect and configure their own databases.
# TODO IMPORTANT: The 'postgres' account DOES NOT HAVE A PASSWORD AT THIS POINT.  For production usage we should add auth;
# however, the commands in the dockerfiles (for OSM, etc.) do not currently have a mechansism for specifying one when running 'psql'.
# This can be added by specifying 'PGPASSWORD=<password> psql ...' when running 'psql'
#
# If the data directory does not exist the database will be initialized using POSTGRES_USER, POSTGRES_PASSWORD and POSTGRES_DB.
# Documentation: https://registry.hub.docker.com/_/postgres/
# TODO Capture the container ID from 'docker run' so that it can be stopped later.
#
docker run --name  $PG_CONTAINER_NAME \
       --detach \
       --volume pg_data:$PG_DATA_DIR \
       --network=$POSM_NET_NAME
       -e POSTGRES_USER=$PG_ADMIN_USER \ 
       -e POSTGRES_PASSWORD=$PG_ADMIN_PASS \ 
       $PG_DOCKER_TAG



# ============================================
# CREATE OSM
# ============================================
#
# Install osmosis.  
# IMPORTANT: According to the announcements on https://wiki.openstreetmap.org/wiki/Osmosis this tool is now in 
# "light maintenance mode" and has been replaced/superceded by other tools, particularly Osmium.  We may want to strongly
# consider replacing Osmosis with Osmium or another tool, but in the meantime we'll see about supporting it.
# The existing ISO-based install uses http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-0.46.tgz, which is at least three years old.
# https://github.com/kartoza/docker-osm may be helpful.

#
# Build OSM image.  Note that the build process requires network access for RUN commands (provided by '--network' param)
# so that it can access the running PostgreSQL instance.
# 
docker build \
        --file ./dockerfile-osm \
        --network=$POSM_NET_NAME \
        --build-arg PG_HOST=$PG_CONTAINER_NAME \
        --build-arg PG_ADMIN_USER=$PG_ADMIN_USER \
        --build-arg PG_ADMIN_PASSWORD=$PG_ADMIN_PASSWORD \
        --build-arg OSM_USER=$osm_pg_owner \ 
        --build-arg OSM_PASSWORD=$osm_pg_pass \ 
        --build-arg OSM_DB=$osm_pg_dbname \
        --tag $OSM_DOCKER_TAG \
        .

# TODO
# -- Figure out how to do the equivalent of su - osm -c "cd '$dst/osm-web' && bundle exec rake db:migrate"
# -- Figure out how to do the 'rake db:migrate', 'rake assets:precompile', and handle the web site portion of OSM (including nginx config).
# -- Figure out how to create the data backup directories 
# -- https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md recommends using Phusion Passenger instead of Rails Server.
# -- https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md recommends using CGIMap to alleviate issues related to 
#    'map' call performance and memory utilization.

#
# Start OSM
# TODO Move to docker-compose
#
#       -e POSTGRES_USER=$osm_pg_owner \ 
#       -e POSTGRES_PASSWORD=$osm_pg_pass \ 
#       -e POSTGRES_DB=$osm_pg_dbname \
docker run --name $OSM_CONTAINER_NAME \
       --detach \
       -e OSM_DST=/opt/osm \
       --network=$POSM_NET_NAME \
       -p 80:3000 \
       $OSM_DOCKER_TAG


# ============================================
# FIN
# ============================================
docker logout \
        $DOCKER_HUB_ADDR

rm -rf $TMP_DIR