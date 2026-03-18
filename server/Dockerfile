FROM node:20-alpine

# Install ffmpeg
RUN apk add --no-cache ffmpeg bash

WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all source files
COPY . .

# Build TypeScript
RUN ./node_modules/typescript/bin/tsc -p ./tsconfig.json

# Expose port
EXPOSE 3000

# Run the compiled JS
CMD ["npm", "run", "start"]