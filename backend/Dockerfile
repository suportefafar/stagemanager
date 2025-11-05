# Stage 1: Build the application
FROM node:20 AS builder

WORKDIR /app

# Copy package.json and package-lock.json first to leverage Docker cache
COPY package.json package-lock.json ./

# Install dependencies
RUN npm i

# Copy the rest of the application source code
COPY . .

# Run the build command
RUN ./node_modules/.bin/babel src --out-dir build

# Stage 2: Create the final production image
FROM node:20-alpine

WORKDIR /app

# Set the timezone for the final image
ENV TZ=America/Sao_Paulo
RUN apk add --no-cache tzdata && \
    ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# Copy package.json and package-lock.json from the builder stage
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/package-lock.json ./package-lock.json

# Copy the build output from the builder stage
COPY --from=builder /app/build ./build

# Copy the production dependencies from the builder stage
COPY --from=builder /app/node_modules ./node_modules

# Expose the port your bot listens on (if any)
# EXPOSE 3xxx

# Set the environment to production
ENV NODE_ENV=production

# The command to run your bot
CMD ["node", "build/index.js"]