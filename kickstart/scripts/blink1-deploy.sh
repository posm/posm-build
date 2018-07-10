#!/bin/bash

deploy_blink1_ubuntu() {
  TMPFILE=$(mktemp --suffix .zip)
  curl -L https://github.com/todbot/blink1/releases/download/v1.98a/blink1-tool-v1.98a-linux-x86_64.zip -o $TMPFILE
  unzip -d /usr/local/bin $TMPFILE
  chmod +x /usr/local/bin/blink1-tool
  rm $TMPFILE

  expand etc/systemd/system/blink1.service /etc/systemd/system/blink1.service
  systemctl enable blink1
}

deploy blink1
