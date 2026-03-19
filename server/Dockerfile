FROM node:22-bookworm

WORKDIR /app

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --ignore-scripts

# Copy the rest of the application
COPY . .

# build the code
RUN yarn build

CMD [ "npm", "start" ]
