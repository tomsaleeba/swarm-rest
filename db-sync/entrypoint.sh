#!/bin/sh
# schedule task in cron and start daemon
: ${CRON_SCHEDULE:?}
redirectToDockerLogs='> /proc/1/fd/1 2> /proc/1/fd/2'
echo "$CRON_SCHEDULE sh /run.sh $redirectToDockerLogs" >> /var/spool/cron/crontabs/root
crond -l 2 -f

