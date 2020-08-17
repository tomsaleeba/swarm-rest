#!/bin/bash
# open a psql shell inside the stack
set -euo pipefail
cd `dirname "$0"`/..

docker exec -it swarmrest_db sh -c 'psql -U $POSTGRES_USER -d $POSTGRES_DB'
