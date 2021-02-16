#!/bin/bash -e


# wait for database
until PGPASSWORD=$OSM_PASSWORD pg_isready -h $PG_HOST -U $OSM_USER
do
  echo "Waiting for postgres"
  sleep 2;
done

# FIXME: Run this only once initially ---------------------------------

# PG_HOST
# OSM_USER
# OSM_PASSWORD
# OSM_DB
# PG_ADMIN_USER
# PG_ADMIN_PASSWORD

# Default posm user info
OSM_POSM_USER="POSM"
OSM_POSM_DESCRIPTION="Portable OpenStreetMap"
OSM_POSM_PASSWORD=awesomeposm


# Create an OSM user.  The username must match what's in the Rails 'database.yml'.
# TODO: Remove || true
PGPASSWORD=$PG_ADMIN_PASSWORD psql \
    -h $PG_HOST \
    -U $PG_ADMIN_USER \
    -c "CREATE ROLE $OSM_USER WITH SUPERUSER PASSWORD '$OSM_PASSWORD' LOGIN;" || true

cd ./osm-web
bundle exec rake db:create

# Load the Postgres btree-gist extension and install the OSM special functions.  Note that there's also a compiled library version; see
# https://github.com/openstreetmap/openstreetmap-website/blob/master/INSTALL.md section entitled 
# 'Installing compiled shared library database functions (optional)' for details.  This is especially
# recommended if applications make a lot of OSM '/changes' API calls (see https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md)
# TODO: Do this on the database dockerfile?
PGPASSWORD=$OSM_PASSWORD psql -h $PG_HOST -U $OSM_USER -d $OSM_DB -c "CREATE EXTENSION postgis" && \
    PGPASSWORD=$OSM_PASSWORD psql -h $PG_HOST -U $OSM_USER -d $OSM_DB -c "CREATE EXTENSION hstore" && \
    PGPASSWORD=$OSM_PASSWORD psql -h $PG_HOST -U $OSM_USER -d $OSM_DB -c "CREATE EXTENSION btree_gist" && \
    PGPASSWORD=$OSM_PASSWORD psql -h $PG_HOST -U $OSM_USER -d $OSM_DB -f $OSM_DST/osm-web/db/functions/functions.sql

bundle exec rake db:migrate
# TODO: Remove || true
bundle exec rake osm:users:create \
    display_name="${OSM_POSM_USER}" \
    description="${OSM_POSM_DESCRIPTION}" \
    password="${OSM_POSM_PASSWORD}" || true
cd ../

# FIXME: Run this only once initially ---------------------------------

cp -r $OSM_DST/osm-web/public /web-static/
cp -r $OSM_DST/osm-web/vendor /web-static/
# (NOT OPTIMAL) Tell Rails to serve static assets.  Longer-term we'll want to front-end OSM with a web server to handle this.
# See https://exceptionshub.com/rails-4-assets-not-loading-in-production.html for more info.
export RAILS_SERVE_STATIC_FILES=true
# Not strictly necessary (I think) since we build the container with this setting enabled.
export RAILS_ENV=production

cd $OSM_DST/osm-web
bundle exec rails server
