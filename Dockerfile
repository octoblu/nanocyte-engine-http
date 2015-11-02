FROM node:4
MAINTAINER Octoblu <docker@octoblu.com>

EXPOSE 80

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD https://meshblu.octoblu.com/publickey /usr/src/app/public-key.json

COPY . /usr/src/app
RUN npm install

CMD [ "npm", "start" ]
