# Stage 1: Build the Go binary
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git ca-certificates tzdata

# Cache Go modules
COPY go.mod go.sum* ./
RUN go mod download

# Copy source code
COPY . .

# Build statically linked binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -ldflags="-w -s" \
    -o /app/server \
    ./cmd/server/main.go

# Stage 2: Minimal runtime image
FROM alpine:3.19

WORKDIR /app

# Copy ca-certificates and timezone data
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /app/server /app/server

# Run as non-root user
USER nobody:nobody

EXPOSE 8080

ENTRYPOINT ["/app/server"]
