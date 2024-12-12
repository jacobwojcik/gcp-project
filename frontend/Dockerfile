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

ENV PORT=8080
ENV NODE_ENV=production
ENV HOSTNAME="0.0.0.0"

EXPOSE 8080

# Use a shell to ensure environment variables are expanded
CMD ["sh", "-c", "pnpm start -p ${PORT}"]
