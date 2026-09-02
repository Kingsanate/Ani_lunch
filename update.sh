#!/usr/bin/env bash
set -e

echo "=========================================="
echo "🚀 AniLunch Zero-Downtime Live Update"
echo "=========================================="

# 1. Pull latest code from git
echo "📥 1. Pulling latest code..."
git pull origin main

# 2. Build updated Flutter Web apps
echo "🔨 2. Building Flutter Web applications..."
mkdir -p web_builds/customer web_builds/vendor web_builds/rider web_builds/admin

if command -v flutter &> /dev/null; then
    echo " -> Building Customer Web..."
    (cd anilunch/anilunch && flutter build web --release && cp -r build/web/* ../../web_builds/customer/)

    echo " -> Building Vendor Web..."
    (cd anilunch_vendor && flutter build web --release && cp -r build/web/* ../web_builds/vendor/)

    echo " -> Building Rider Web..."
    (cd anilunch_rider && flutter build web --release && cp -r build/web/* ../web_builds/rider/)

    echo " -> Building Admin Web..."
    (cd anilunch_admin/anilunch_admin && flutter build web --release && cp -r build/web/* ../../web_builds/admin/)
fi

# 3. Hot-swap the Go API backend container in 1 second
echo "⚡ 3. Hot-swapping Go API backend..."
docker compose -f docker-compose.prod.yml up -d --build --no-deps api

# 4. Reload Caddy without downtime
echo "🔒 4. Reloading Caddy web server..."
docker compose -f docker-compose.prod.yml exec caddy caddy reload --config /etc/caddy/Caddyfile || true

echo "=========================================="
echo "✅ Update Complete! All apps are live."
echo "=========================================="
