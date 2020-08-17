#!/bin/bash
# runs the script.sql against the stack
set -euo pipefail
cd `dirname "$0"`/..

cat script.sql | docker exec -i swarmrest_db sh -c 'psql -U $POSTGRES_USER -d $POSTGRES_DB --set=ON_ERROR_STOP=1'
