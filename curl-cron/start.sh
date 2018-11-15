#!/bin/sh
set -e
: ${ES_HOST:?}
: ${ES_PORT:?}
: ${ES_SNAPSHOT_REPO:?}
: ${BACKUP_PREFIX:?}
: ${CRON_SCHEDULE:?}
redirectToDockerLogs='> /dev/stdout 2> /dev/stderr'
echo "$CRON_SCHEDULE /curl.sh $redirectToDockerLogs" >> /var/spool/cron/crontabs/root
crond -l 2 -f

