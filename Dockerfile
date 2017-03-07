FROM octoblu/node:7-alpine-gyp

EXPOSE 80
HEALTHCHECK CMD curl --fail http://localhost:80/proofoflife || exit 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY package.json yarn.lock /usr/src/app/

RUN yarn install --production

COPY . /usr/src/app

CMD [ "node", "command.js" ]
