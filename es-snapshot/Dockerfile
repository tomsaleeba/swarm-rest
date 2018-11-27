FROM alpine:3.7
LABEL author="Tom Saleeba"
LABEL description="curl running under cron for periodic snapshots of ElasticSearch"

RUN apk --no-cache add curl

ADD *.sh /
RUN chmod +x /*.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD [""]

