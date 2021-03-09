#!/bin/bash

if [ -z "$1" ]; then
    echo "Must pass path to snapshot file"
    exit 1
fi

SNAPSHOT_FILE="$1"

echo "Dont forget to port forward consul to local host to be able to access the API."
echo "Use: kubectl port-forward -n vault service/consul-consul-server 8500:8500"

if test -f "$SNAPSHOT_FILE"; then

    echo "Uploading snapshot to Consul. Will retry 50 times on fail."

    curl \
        --request PUT \
        --data-binary @$SNAPSHOT_FILE \
        http://127.0.0.1:8500/v1/snapshot \
        --connect-timeout 10 \
        --retry 50 \
        --retry-delay 5 \
        --retry-connrefused

else
    echo "Could not find snapshot.tgz"
fi
