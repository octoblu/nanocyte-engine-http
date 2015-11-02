FROM node:4
MAINTAINER Octoblu <docker@octoblu.com>

EXPOSE 80

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD https://raw.githubusercontent.com/octoblu/nanocyte-node-registry/master/registry.json /usr/src/app/nanocyte-node-registry.json
ADD https://meshblu.octoblu.com/publickey /usr/src/app/public-key.json

COPY . /usr/src/app
RUN npm install

CMD [ "npm", "start" ]
