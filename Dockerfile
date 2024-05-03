FROM node:10

ENV WORKDIR /usr/app
ENV USER node
# Create app directory
WORKDIR $WORKDIR

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./

RUN npm install
# If you are building your code for production
# RUN npm ci --only=production

# Bundle app source
COPY . .

HEALTHCHECK --interval=30s --timeout=3s \
	CMD curl -f http://192.168.240.254:8080 || exit 1

USER $USER
EXPOSE 8080
CMD [ "node", "server.js" ]