#!/bin/bash
# performs a data-only pgsync
set -euo pipefail
cd `dirname "$0"`/..

docker exec -i swarmrest_db_sync sh -c 'sh /app/run.sh'
