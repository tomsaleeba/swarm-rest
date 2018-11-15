#!/bin/sh
# schedule task in cron and start daemon
: ${CRON_SCHEDULE:?}
redirectToDockerLogs='> /dev/stdout 2> /dev/stderr'
echo "$CRON_SCHEDULE sh /run.sh $redirectToDockerLogs" >> /var/spool/cron/crontabs/root
crond -l 2 -f

