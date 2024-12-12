FROM --platform=linux/amd64 node:18-slim

# Install pnpm
RUN npm install -g pnpm

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN pnpm install

# Copy source files
COPY . .

# Build the application
RUN pnpm build

# Make sure the application listens on PORT environment variable
ENV PORT=8080

EXPOSE 8080

# Use a direct node command instead of pnpm
CMD ["node", "dist/index.js"]
