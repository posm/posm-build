#!/usr/bin/env bash

set -euo pipefail

posm_hostname=$(jq -r .posm_hostname /etc/posm.json)
webodm_fqdn=$(jq -r .webodm_fqdn /etc/posm.json)
webodm_user=$(jq -r .webodm_user /etc/posm.json)
webodm_password=$(jq -r .webodm_password /etc/posm.json)
hostname=$(hostname -I | awk '{print $1}')

cookiejar=$(mktemp)
token=$(echo "{\"username\": \"${webodm_user}\", \"password\": \"${webodm_password}\"}" | \
  curl -sf \
    -c $cookiejar \
    -X POST \
    -H "Host: ${webodm_fqdn}" \
    -H "Content-Type: application/json" \
    -d @- \
    "http://${posm_hostname}.local/api/token-auth/" | jq -r .token)

csrf_token=$(grep csrftoken ${cookiejar} | awk '{print $7}')

echo "{\"hostname\": \"${hostname}\", \"port\": 3000}" | \
  curl -sf \
    -b @${cookiejar} \
    -H "Host: $webodm_fqdn" \
    -H "Content-Type: application/json" \
    -H "Authorization: JWT ${token}" \
    -H "X-CSRFToken: ${csrf_token}" \
    -X POST \
    -d @- \
    "http://${posm_hostname}.local/api/processingnodes/"

rm -f ${cookiejar}