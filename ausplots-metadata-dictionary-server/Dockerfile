FROM node:14-alpine3.12 as withDeps

ARG NODE_ENV

# set $HOME so yarn commands don't complain about not finding a config file:
#    Error: ENOTDIR: not a directory, open '/dev/null/.config/yarn'
ENV NODE_ENV=${NODE_ENV:-production} \
    HOME=/tmp
WORKDIR /app
ADD package.json yarn.lock ./
RUN yarn install --prod --frozen-lockfile \
      && yarn cache clean

FROM withDeps
EXPOSE 3000
# the 'guest' user is built in to Alpine
USER guest
ADD --chown=guest:users . ./
#
CMD [ "yarn", "start:prod" ]
