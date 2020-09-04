FROM node:14-buster

ADD . /app
WORKDIR /app
RUN yarn install --frozen-lockfile

CMD [ "yarn", "start:prod" ]
