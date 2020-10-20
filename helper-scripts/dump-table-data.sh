#!/bin/bash
# dumps table data to stdout
set -euo pipefail
cd `dirname "$0"`/..

docker exec \
  -it \
  swarmrest_db \
  sh -c "pg_dump -U \$POSTGRES_USER -d \$POSTGRES_DB --inserts --no-owner --no-privileges --data-only --table ${1:?first param must be table name}"
