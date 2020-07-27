#!/bin/bash

docs_dir=/opt/docs

deploy_docs_ubuntu() {
    mkdir -p $docs_dir
    # install pip
    apt install pip
    # install virtualenv
    pip install virtualenv

    # Clone the docs repo
    git clone https://github.com/posm/docs $docs_dir

    cd $docs_dir && virtualenv venv
    # Activate virtuanenv install requirements and make deploy
    source $docs_dir/venv/bin/activate
    cd $docs_dir && pip install -r requirements.txt
    cd $docs_dir && make deploy

    # Copy nginx confs
    expand etc/nginx-docs.conf /etc/nginx/sites-available/docs
    ln -s -f ../sites-available/docs /etc/nginx/sites-enabled/

    # No need to enable services it's just serving static files
}

deploy docs
