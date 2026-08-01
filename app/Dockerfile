FROM node:20-alpine

WORKDIR /usr/src/app

COPY package.json package-lock.json* ./

RUN npm install --omit=dev

COPY server.js ./

EXPOSE 3000

USER node

CMD ["node", "server.js"]