#!/usr/bin/env bash

set -euo pipefail

posm_hostname=$(jq -r .posm_hostname /etc/posm.json)
hostname=${1:-$(hostname -I | awk '{print $1}')}

cat << EOF | nc -N ${posm_hostname}.local 28080
NODE ADD ${hostname} 3001
EOF