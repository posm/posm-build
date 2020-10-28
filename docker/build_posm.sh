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
PG_HOST_DATA_DIR=/Users/cvonsee/temp/pg_data
PG_CONTAINER_DATA_DIR=/var/lib/postgresql/data
PG_ADMIN_USER=postgres
PG_ADMIN_PASSWORD=openstreetmap

OSM_DOCKER_TAG=posm/posm-osm:0.1
OSM_CONTAINER_NAME=posm-osm
OSM_IMPORT_DIR=/Users/cvonsee/temp/osm_import
OSM_EXPORT_DIR=/Users/cvonsee/temp/osm_export

ARG OSMOSIS_VER=0.48.3
ARG JAVA_VER=8u272-jre-buster
OSMOSIS_CONTAINER_NAME=posm-osmosis
OSMOSIS_DOCKER_TAG=posm/posm-osmosis:0.1

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
mkdir -p $PG_HOST_DATA_DIR

docker run --name  $PG_CONTAINER_NAME \
       --detach \
       --volume $PG_HOST_DATA_DIR:$PG_CONTAINER_DATA_DIR \
       --network=$POSM_NET_NAME \
       -e POSTGRES_USER=$PG_ADMIN_USER \ 
       -e POSTGRES_PASSWORD=$PG_ADMIN_PASS \ 
       $PG_DOCKER_TAG



# ============================================
# CREATE OSM
# ============================================
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
# -- Figure out how to create the data backup directories 
# -- https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md recommends using Phusion Passenger instead of Rails Server.
# -- https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md recommends using CGIMap to alleviate issues related to 
#    'map' call performance and memory utilization.

#
# Start OSM.
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
# CREATE OSMOSIS
# ============================================
#
# Install osmosis as a container that can be run via 'docker run' to import data into the local OSM.  
# IMPORTANT: According to the announcements on https://wiki.openstreetmap.org/wiki/Osmosis this tool is now in 
# "light maintenance mode" and has been replaced/superceded by other tools.  I mentioned this on the "HOT OSM" and "OSM World"
# chats, and the consensus seems to be that there is no real replacement for "osmosis" and that it's not going anywhere any time soon.
#
# The LXC-based POSM used "http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-${osmosis_ver}.tgz"; note that we're using the 
# official Github-based releases instead.
docker build \
        --file ./dockerfile-osmosis \
        --network=$POSM_NET_NAME \
        --build-arg OSMOSIS_VER=0.48.3 \
        --build-arg JAVA_VER=8u272-jre-buster \
        --build-arg OSM_CONTAINER_NAME=$OSM_CONTAINER_NAME \
        --build-arg OSM_USER=$osm_pg_owner \ 
        --build-arg OSM_PASSWORD=$osm_pg_pass \ 
        --build-arg OSM_DB=$osm_pg_dbname \
        --tag $OSMOSIS_DOCKER_TAG \
        .

# 
# Run osmosis
mkdir -p $OSM_IMPORT_DIR
mkdir -p $OSM_EXPORT_DIR
docker run --name $OSMOSIS_CONTAINER_NAME \
       --detach \
       --network=$POSM_NET_NAME \
        --volume osm_import:$OSM_IMPORT_DIR \
        --volume osm_export:$OSM_EXPORT_DIR \
       $OSMOSIS_DOCKER_TAG



# ============================================
# FIN
# ============================================
docker logout \
        $DOCKER_HUB_ADDR

rm -rf $TMP_DIR