#!/bin/bash
# create the snapshot repo in ES
: ${ES_SNAPSHOT_REPO:?}
: ${AWS_BUCKET:?}
curl \
  -X PUT \
  -H 'content-type: application/json' \
  -d '{"type":"s3","settings":{"bucket":"'$AWS_BUCKET'"}}' \
  http://localhost:9200/_snapshot/${ES_SNAPSHOT_REPO}

