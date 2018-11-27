#!/bin/sh
set -e
: ${ES_HOST:?}
: ${ES_PORT:?}
: ${ES_SNAPSHOT_REPO:?}
: ${BACKUP_PREFIX:?}
: ${CRON_SCHEDULE:?}
redirectToDockerLogs='> /proc/1/fd/1 2> /proc/1/fd/2'
echo "$CRON_SCHEDULE sh /run.sh $redirectToDockerLogs" > /var/spool/cron/crontabs/root
crond -l 2 -f

