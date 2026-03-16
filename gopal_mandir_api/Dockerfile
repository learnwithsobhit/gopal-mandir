# Build stage
FROM rust:1.94-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*

# Copy manifests first for dependency caching
COPY Cargo.toml Cargo.lock ./

# Create a dummy src to build dependencies
RUN mkdir src && echo 'fn main() { println!("placeholder"); }' > src/main.rs
RUN cargo build --release
RUN rm -rf src

# Copy real source code and migrations
COPY src ./src
COPY migrations ./migrations

# Build the actual binary (touch to invalidate cache)
RUN touch src/main.rs && cargo build --release

# Runtime stage — minimal image
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled binary and migrations from builder
COPY --from=builder /app/target/release/gopal_mandir_api .
COPY --from=builder /app/migrations ./migrations

# Railway provides PORT and DATABASE_URL env vars
ENV PORT=8080
EXPOSE 8080

CMD ["./gopal_mandir_api"]
