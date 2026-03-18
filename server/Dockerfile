# Use Node Alpine
FROM node:20-alpine

# Install ffmpeg (if needed)
RUN apk add --no-cache ffmpeg bash

# Set working directory
WORKDIR /app

# Copy package.json & package-lock.json first (for caching)
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the source code
COPY . .

# Build TypeScript
RUN npm run build

# Expose port
EXPOSE 3000

# Run compiled JavaScript
CMD ["npm", "run", "start"]