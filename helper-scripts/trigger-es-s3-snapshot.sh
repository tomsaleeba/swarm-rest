#!/bin/bash
# triggers the snapshot container to perform an ElasticSearch backup to S3
set -euo pipefail
cd `dirname "$0"`

docker exec -i swarmrest_es_backup sh -c '/run.sh'
