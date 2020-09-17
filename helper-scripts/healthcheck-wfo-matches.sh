#!/bin/bash
# runs the healthcheck script against the stack
set -euo pipefail
cd `dirname "$0"`

cat wfo_healthcheck.sql | docker exec -i swarmrest_db sh -c 'psql --quiet -U $POSTGRES_USER -d $POSTGRES_DB --set=ON_ERROR_STOP=1'
