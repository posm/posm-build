FROM ruby:2.7.2

ARG OSM_DST=/opt/osm

# base URL for iD app definition
ARG OSM_FQDN=posm.io
ARG OSM_BASE_URL="http://${OSM_FQDN}"

WORKDIR /opt/osm

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# firefox-geckodriver equivalent needed?
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        libmagickwand-dev \
        libxml2-dev \
        libxslt1-dev \
        nodejs \
        npm \
        yarn \
        apache2 \
        apache2-dev \
        build-essential \
        git-core \
        postgresql-contrib \
        postgresql-server-dev-all \
        libpq-dev \
        libsasl2-dev \
        imagemagick \
        libffi-dev \
        libgd-dev \
        libarchive-dev \
        libbz2-dev \
        jq

# Needed by something in 'rake db:create'
# TODO I get the following weird error when I build this image - need to check nodejs and npm versions installed above:
#   npm WARN npm npm does not support Node.js v10.21.0
#   npm WARN npm You should probably upgrade to a newer version of node as we
#   npm WARN npm can't make any promises that npm will work with this version.
#   npm WARN npm Supported releases of Node.js are the latest release of 4, 6, 7, 8, 9.
#   npm WARN npm You can find the latest version at https://nodejs.org/
RUN npm install -g svgo

# The current ARC openstreetmap-website is made for a really old version of Ruby and has a ton of dependency version issues
# in Gemfile.lock, so as a test we're going to use the official OpenStreetMap version.
# RUN git clone --depth=1 https://github.com/AmericanRedCross/openstreetmap-website $OSM_DST/osm-web
RUN git clone --depth=1 https://github.com/openstreetmap/openstreetmap-website $OSM_DST/osm-web

RUN cd $OSM_DST/osm-web && \
    bundle install && \
    bundle exec rake yarn:install && \
    touch config/settings.local.yml && \
    cp config/example.storage.yml config/storage.yml

# Add our config/database.yml, which has the appropriate user/pass/host set.
# TODO Generate this dynamically in build_posm.sh
ADD config/database.yml $OSM_DST/osm-web/config/database.yml
ADD config/initializers/action_mailer.rb $OSM_DST/osm-web/config/initializers/action_mailer.rb
ADD lib/tasks/osm.rake $OSM_DST/osm-web/lib/tasks/osm.rake

# IMPORTANT The following two environment variables are required by 'rake db:create' and 'rake db:migrate'.  Setting RAILS_ENV to 'production' creates only the
# production database (not dev or test); setting DISABLE_DATABASE_ENVIRONMENT_CHECK to '1' allows db:migrate to do its thing against a production database
# without complaining.
ENV RAILS_ENV production
ENV DISABLE_DATABASE_ENVIRONMENT_CHECK 1

# Required because we're running in production mode?  This step takes a while...
# See https://github.com/openstreetmap/openstreetmap-website/issues/2016
RUN cd $OSM_DST/osm-web \
    && bundle exec rake i18n:js:export \
    && bundle exec rake assets:precompile

# Set up the command that will run when the container is started.
ADD run_osm.sh /

# TODO https://github.com/openstreetmap/openstreetmap-website/blob/master/CONFIGURE.md recommends using the
# Phusion Passenger server instead of Rails in production.
CMD ["sh", "-c", "/run_osm.sh"]
