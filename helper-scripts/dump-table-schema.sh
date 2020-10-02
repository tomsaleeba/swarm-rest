#!/bin/bash
# dumps a table schema to stdout
set -euo pipefail
cd `dirname "$0"`/..

docker exec \
  -it \
  swarmrest_db \
  sh -c "pg_dump -U \$POSTGRES_USER -d \$POSTGRES_DB --no-owner --no-privileges --schema-only --table ${1:?first param must be table name}"
