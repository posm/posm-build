#!/bin/bash

deploy_blink1_ubuntu() {
  TMPFILE=$(mktemp --suffix .zip)
  curl -L https://github.com/todbot/blink1/releases/download/v1.96/blink1-tool-v1.96-linux-x86_64.zip -o $TMPFILE
  unzip -d /usr/local/bin $TMPFILE
  chmod +x /usr/local/bin/blink1-tool
  rm $TMPFILE

  expand etc/init/blink1.conf /etc/init/blink1.conf
}

deploy blink1
