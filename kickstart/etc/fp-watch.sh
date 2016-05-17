#!/usr/bin/env bash

DATA_DIR=/opt/data/fieldpapers
PENDING_DIR=/opt/data/fieldpapers/pending
SNAPSHOTS_DIR=/opt/data/fieldpapers/snapshots
fp_api_base_url=$(jq -r .fp_api_base_url /etc/posm.json)

mkdir -p "$PENDING_DIR"
mkdir -p "$SNAPSHOTS_DIR"
chown fp:fp "$PENDING_DIR"
chown fp:fp "$SNAPSHOTS_DIR"

inotifywait -q -m -e close_write --format '%w%f' "$DATA_DIR" | while read filename; do
    # ignore data in folders
    if [ "$(dirname $filename)" != "$DATA_DIR" ]; then
      continue
    fi

    # is it empty?
    test -s $filename || continue

    # does anything have it open?
    fuser $filename > /dev/null 2>&1 && continue

    case "$filename" in
        # ignore OSX-style metadata
        *._*)
            continue

           ;;

        *.[Pp][Dd][Ff]|*.[Pp][Nn][Gg]|*.[Jj][Pp][Ee]?[Gg])
            echo "Uploading ${filename}..."

            fn=$(basename $filename)
            pending="${PENDING_DIR}/${fn}"

            # copy it into a staging directory
            mv $filename "$PENDING_DIR"
            # delete OS X metadata (if present)
            rm -f ${DATA_DIR}/._${fn}

            # upload to FP
            snapshot_url=$(curl -sF "snapshot[scene]=@${pending};type=$(file -b --mime-type ${pending})" ${fp_api_base_url}/snapshots -o /dev/null -w "%{redirect_url}")

            IFS=/ read -a parts <<< "$snapshot_url"
            snapshot_id=${parts[5]}

            mv $pending "${SNAPSHOTS_DIR}/${snapshot_id}-${fn}"

            echo "Snapshot URL: ${snapshot_url}"

            ;;
    esac
done
