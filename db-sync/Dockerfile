FROM ruby:2.5-alpine3.8
LABEL author="Tom Saleeba"
LABEL description="pgsync running under cron for periodic DB synchronisation"

RUN \
  mkdir /git && \
  cd /git && \
  apk add --no-cache postgresql-client postgresql-dev && \
  apk add --no-cache --virtual .build-deps git build-base && \
  git clone https://github.com/tomsaleeba/pgsync && \
  cd pgsync && \
  git checkout tomsaleeba-patch-1 && \
  gem build pgsync.gemspec && \
  gem install pgsync-*.gem && \
  apk del .build-deps

ADD *.sh /
ENTRYPOINT [ "/bin/sh", "/entrypoint.sh" ]

