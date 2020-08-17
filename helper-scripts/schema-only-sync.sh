#!/bin/bash
# performs a schema-only pgsync, will need a data sync after
set -euo pipefail
cd `dirname "$0"`/..

docker exec -i swarmrest_db_sync sh -c 'SCHEMA_ONLY=1 sh /app/run.sh'
