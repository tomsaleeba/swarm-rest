#!/bin/bash
# creates a read-only user that can select from any existing or future created tables

# warning: user will be allowed to create tables in public, as that's enabled by default. They can't
# modify any important tables though.
set -e

RO_USER_NAME=${RO_USER_NAME:-readonly}
RO_USER_PASS=${RO_USER_PASS:-readonlypassword}
echo "Creating readonly user with username='$RO_USER_NAME' and password='$RO_USER_PASS'"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
  CREATE USER $RO_USER_NAME WITH PASSWORD '$RO_USER_PASS';
  GRANT SELECT ON ALL TABLES IN SCHEMA public TO $RO_USER_NAME;
  GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO $RO_USER_NAME;
  ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO $RO_USER_NAME;
EOSQL
