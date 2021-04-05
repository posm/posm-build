#
# This image does not have a CMD or ENTRYPOINT because it's designed specifically to be run via "docker run --rm" with args that
# specify a .pbf file to load into OSM.
#
# VERY IMPORTANT!
# You'll note that the ARG statements are repeted both before AND after the FROM statement.  That's because FROM is the boundary
# of a build stage, and the ARG values get reset at the beginning of each build stage.  Go figure.
ARG OSMOSIS_VER=0.48.3
ARG JAVA_VER=8u272-jre-buster

FROM openjdk:${JAVA_VER}

# SEE THE VERY IMPORTANT NOTE AT THE TOP OF THIS DOCKERFILE.
ARG OSMOSIS_VER=0.46
ARG JAVA_VER=8u272-jre-buster

ARG OSMOSIS_INSTALL_DIR=/opt/osmosis

RUN mkdir -p /osm_import && \
    mkdir -p /osm_export
VOLUME [ "/osm_import", "/osm_export" ]

# Install osmosis from the Github releases
RUN wget https://github.com/openstreetmap/osmosis/releases/download/${OSMOSIS_VER}/osmosis-${OSMOSIS_VER}.tgz && \
    mkdir -p $OSMOSIS_INSTALL_DIR && \
    mv osmosis-${OSMOSIS_VER}.tgz $OSMOSIS_INSTALL_DIR && \
    cd $OSMOSIS_INSTALL_DIR && \
    tar xvfz osmosis-${OSMOSIS_VER}.tgz && \
    rm osmosis-${OSMOSIS_VER}.tgz && \
    chmod a+x bin/osmosis

ADD entry_point.sh osm-sample.properties /

ENTRYPOINT ["/entry_point.sh"]
