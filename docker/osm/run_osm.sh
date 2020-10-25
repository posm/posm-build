# (NOT OPTIMAL) Tell Rails to serve static assets.  Longer-term we'll want to front-end OSM with a web server to handle this.
# See https://exceptionshub.com/rails-4-assets-not-loading-in-production.html for more info.
export RAILS_SERVE_STATIC_FILES=true
# Not strictly necessary (I think) since we build the container with this setting enabled.
export RAILS_ENV=production

cd $OSM_DST/osm-web
bundle exec rails server