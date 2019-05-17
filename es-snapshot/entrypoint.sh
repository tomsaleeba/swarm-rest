#!/bin/sh
set -euxo pipefail

# assert env vars exist with bash parameter expansion (http://wiki.bash-hackers.org/syntax/pe#display_error_if_null_or_unset)
: ${ES_HOST:?}
: ${ES_PORT:?}
: ${ES_SNAPSHOT_REPO:?}
: ${BACKUP_PREFIX:?}
: ${CRON_SCHEDULE:?}

echo "$CRON_SCHEDULE sh /run.sh" > /var/spool/cron/crontabs/root
crond -f

