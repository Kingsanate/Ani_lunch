#!/usr/bin/env bash
set -e

echo "=========================================="
echo "🚀 AniLunch Initial VPS Production Deploy"
echo "=========================================="

# 1. Ensure Docker is installed
if ! command -v docker &> /dev/null; then
    echo "📦 Installing Docker & Docker Compose..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
fi

# 2. Setup web build directories
mkdir -p web_builds/customer web_builds/vendor web_builds/rider web_builds/admin

# 3. Boot full stack
echo "⚡ Launching PostgreSQL 16, Redis, NATS, Go API & Caddy..."
docker compose -f docker-compose.prod.yml up -d --build

echo "=========================================="
echo "🎉 Deployment Successful! Everything is running."
echo "=========================================="
