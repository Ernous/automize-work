FROM crystallang/crystal:1.11-alpine as builder

# Install build dependencies
RUN apk add --no-cache \
    sqlite-dev \
    sqlite \
    git \
    build-base

# Set working directory
WORKDIR /app

# Copy shard files
COPY shard.yml shard.lock* ./

# Install dependencies
RUN shards install

# Copy source code
COPY . .

# Build the application
RUN crystal build --release --no-debug src/git_commit_telegram_bot.cr -o git-commit-telegram-bot

# Create runtime image
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache \
    sqlite \
    ca-certificates

# Create app user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/git-commit-telegram-bot .

# Create data directory
RUN mkdir -p data && chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Set environment variables
ENV PORT=3000
ENV KEMAL_ENV=production

# Run the application
CMD ["./git-commit-telegram-bot"]