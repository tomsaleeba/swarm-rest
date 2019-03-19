#!/bin/sh
# hits a URL on ElasticSearch to trigger a snapshot.
set -euxo pipefail
uniqueFragment=`date +%Y%m%d_%H%M`
url=http://${ES_HOST}:${ES_PORT}/_snapshot/${ES_SNAPSHOT_REPO}/${BACKUP_PREFIX}.${uniqueFragment}?wait_for_completion=true
echo "$(date) triggering ES snapshot"
curl -X PUT $url
echo -e "\n"

