#! /bin/bash

PWD=${pwd}
TMP_DIR=$PWD
POSM_BUILD_DIR=$TMP_DIR/posm-build
POSM_BUILD_KICKSTART_ETC_DIR=$POSM_BUILD_DIR/kickstart/etc
FP_WEB_DIR=$TMP_DIR/fp-web

# TODO Figure out a better way to handle these environment dependencies from config/providers.json
posm_fqdn=127.0.0.

# Clone posm-build so we have access to all of the junk POSM needs
git clone https://github.com/posm/posm-build $POSM_BUILD_DIR

# Clone fp-web and copy all of the necessary stuff from posm-build.
# CONFIRM that direnv will load the .env if it exists (according to the commits for fp-web)
git clone https://github.com/fieldpapers/fp-web.git $FP_WEB_DIR

cp $POSM_BUILD_KICKSTART_ETC_DIR/fp-web.env $FP_WEB_DIR/.env
cp $POSM_BUILD_KICKSTART_ETC_DIR/fieldpapers/database.yml $FP_WEB_DIR/config/database.yml
cp $POSM_BUILD_KICKSTART_ETC_DIR/fp-providers.json $FP_WEB_DIR/config/providers.json

# TODO initialize the Postgres database.  This needs to happen once we figure out where the database will actually live.
# See posm-build/kickstart/scripts/fieldpapers-deploy.sh line 124-127

# Build the dockerfile from the modified Github repository
cd $FP_WEB_DIR && \
   docker build --build-arg posm_fqdn=127.0.0.1  

# TODO
# Download https://github.com/fieldpapers/fp-tiler and create a Docker image
# Download https://github.com/fieldpapers/fp-tasks and create a Docker image
# Take a look at the code in posm-build/kickstart/scripts/fieldpapers-deploy.sh deploy_fp_legacy() and see if this still needs to be done
