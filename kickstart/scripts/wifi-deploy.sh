#!/bin/bash

# Should use Ubuntu linux-image-3.19.0-42-generic
deploy_wifi_ubuntu() {
	ln -s /lib/firmware/iwlwifi-7265D-12.ucode /lib/firmware/iwlwifi-3165-9.ucode
	ln -s /lib/firmware/iwlwifi-7265-12.ucode /lib/firmware/iwlwifi-3165-12.ucode
	apt-get install -y hostapd
}

deploy wifi
