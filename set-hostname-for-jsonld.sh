#!/bin/bash
# (re)creates the DB function to return the hostname prefix to use in all JSON-LD URLs
set -e

urlScheme=${URL_SCHEME:-http} # to override: env URL_SCHEME=https ./set-hostname-for-jsonld.sh

query=''
query+='DROP FUNCTION IF EXISTS public_url_prefix;'
query+='CREATE FUNCTION public_url_prefix() RETURNS text AS \$\$ BEGIN'
query+="  RETURN '$urlScheme://\${PUBLIC_HOSTNAME:?}:\${PUBLIC_PORT:?}';"
query+='END \$\$ LANGUAGE plpgsql IMMUTABLE;'
query+=''
query+="SELECT 'public_url_prefix set to ' || public_url_prefix() AS outcome;"
docker exec -it swarmrest_db sh -c "echo \"$query\" | psql -U \$POSTGRES_USER -d \$POSTGRES_DB"
