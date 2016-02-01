#!/bin/bash

carto_user="${carto_user:-${osm_pg_owner:-gis}}"
dst="/opt/$carto_user"

deploy_carto_ubuntu() {
  apt-get install nodejs -y
  deploy_carto_fonts
  deploy_carto_common
}

deploy_carto_fonts() {
  #apt-get install texlive-fonts-extra -y
  #from_github "https://github.com/google/fonts" "$dst/fonts"
  wget -P "$dst/fonts" "https://github.com/google/fonts/raw/master/apache/opensans/OpenSans-Bold.ttf"
}

deploy_carto_common() {
  useradd -c 'OSM/GIS User' -d "$dst" -m -r -s /bin/bash -U "$carto_user"

  from_github "https://github.com/AmericanRedCross/posm-carto" "$dst/posm-carto"
  chown "$carto_user:$carto_user" "$dst/posm-carto"

  su - "$carto_user" -c "cd '$dst/posm-carto' && npm install --quiet"
  su - "$carto_user" -c "make -C '$dst/posm-carto project.xml'"
  mkdir -p "$dst/posm-carto/font/"
  ln -s "$dst/fonts/OpenSans-Bold.ttf" "$dst/posm-carto/font/"

  rm "$dst/mm"
  ln -s posm-carto "$dst/mm"

}

deploy carto
