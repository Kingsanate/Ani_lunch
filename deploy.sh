#!/usr/bin/env bash
# ==============================================================================
# AniLunch / AniMeat — Automated Staging & Production Deployment Script
# Targets: Ubuntu / Debian / RHEL / Oracle Linux / AWS EC2 / DigitalOcean
# Stack: Caddy LB + 3x Go API + Postgres 16 (Primary + Replica) + PgBouncer + Redis 7 + NATS JetStream
# ==============================================================================
set -euo pipefail

# --- Color Formatting ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${CYAN}${BOLD}"
echo "  ___         _ _                     _     "
echo " / _ \       (_) |                   | |    "
echo "/ /_\ \_ __   _| |    _   _ _ __   ___| |__  "
echo "|  _  | '_ \ | | |   | | | | '_ \ / __| '_ \ "
echo "| | | | | | || | |___| |_| | | | | (__| | | |"
echo "\_| |_/_| |_|/_\_____/\__,_|_| |_|\___|_| |_|"
echo "          Phase 14 Cluster Deployment        "
echo -e "${NC}"

# --- Step 1: Detect Project Root ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
info "Working directory: $SCRIPT_DIR"

# --- Step 2: Verify Host Dependencies ---
info "Checking host prerequisites..."

if ! command -v docker &> /dev/null; then
    error "Docker is not installed. Please install Docker: https://docs.docker.com/engine/install/"
fi

# Detect docker compose syntax (V2 plugin vs V1 standalone)
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    error "Docker Compose is not installed. Please install docker-compose-plugin."
fi
info "Using Docker Compose command: $DOCKER_COMPOSE"

if ! command -v curl &> /dev/null; then
    warn "curl is not installed. Install curl for automatic health probes."
fi

# --- Step 3: Git Pull Latest Code ---
if [ -d ".git" ] && command -v git &> /dev/null; then
    info "Pulling latest code from git..."
    git pull --rebase || warn "Could not pull latest code; proceeding with local workspace."
fi

# --- Step 4: Environment Validation ---
ENV_FILE="backend/.env"
EXAMPLE_FILE="backend/.env.example"

if [ ! -f "$ENV_FILE" ]; then
    if [ -f "$EXAMPLE_FILE" ]; then
        warn "$ENV_FILE not found. Creating from $EXAMPLE_FILE..."
        cp "$EXAMPLE_FILE" "$ENV_FILE"
        warn "Please inspect and update $ENV_FILE before production usage."
    else
        error "No .env or .env.example found in backend/ directory."
    fi
fi

info "Validating environment configuration in $ENV_FILE..."

# Check critical variables
check_var() {
    local var_name="$1"
    local val
    val=$(grep -E "^${var_name}=" "$ENV_FILE" | cut -d '=' -f2- | tr -d '"' | tr -d "'" || true)
    if [ -z "$val" ]; then
        warn "Missing or empty environment variable: $var_name in $ENV_FILE"
    else
        echo "  ✓ $var_name is set"
    fi
}

check_var "DATABASE_URL"
check_var "REDIS_URL"
check_var "NATS_URL"
check_var "SUPABASE_JWT_SECRET"
check_var "R2_ACCOUNT_ID"
check_var "R2_ACCESS_KEY_ID"
check_var "R2_SECRET_ACCESS_KEY"
check_var "R2_BUCKET"

# Security check on JWT Secret
JWT_SECRET=$(grep -E "^SUPABASE_JWT_SECRET=" "$ENV_FILE" | cut -d '=' -f2- | tr -d '"' | tr -d "'" || true)
if [[ "$JWT_SECRET" == *"super-secret-jwt-key-for-local-dev-must-change"* ]]; then
    warn "SUPABASE_JWT_SECRET is using the insecure default dev key. Change it for production!"
fi

# --- Step 5: Build and Launch Horizontal Cluster ---
COMPOSE_FILE="backend/docker-compose.lb.yml"
info "Starting cluster with compose file: $COMPOSE_FILE..."

# Stop any conflicting containers gracefully
$DOCKER_COMPOSE -f "$COMPOSE_FILE" down --remove-orphans || true

# Build images and start all services (detached)
$DOCKER_COMPOSE -f "$COMPOSE_FILE" up -d --build

success "All container services launched."

# --- Step 6: Wait & Health Probe ---
info "Waiting for load balancer and API replicas to pass health checks..."

MAX_ATTEMPTS=30
ATTEMPT=1
HEALTH_URL="http://localhost:8080/health/ready"

until curl -s -f "$HEALTH_URL" &> /dev/null || [ $ATTEMPT -ge $MAX_ATTEMPTS ]; do
    echo -n "."
    sleep 2
    ATTEMPT=$((ATTEMPT + 1))
done
echo ""

if curl -s -f "$HEALTH_URL" &> /dev/null; then
    HEALTH_RESP=$(curl -s "$HEALTH_URL")
    success "Cluster is healthy and ready to serve traffic! (Response: $HEALTH_RESP)"
else
    warn "Health probe did not respond within 60 seconds."
    warn "Check container logs with: $DOCKER_COMPOSE -f $COMPOSE_FILE logs"
fi

# --- Step 7: Container Status Summary ---
echo ""
info "Active Container Topology:"
$DOCKER_COMPOSE -f "$COMPOSE_FILE" ps

echo ""
echo -e "${GREEN}${BOLD}======================================================${NC}"
echo -e "${GREEN}${BOLD}       AniLunch Horizontal Cluster is LIVE!           ${NC}"
echo -e "${GREEN}${BOLD}======================================================${NC}"
echo -e " • Public API (via Caddy LB):  ${CYAN}http://localhost:8080${NC}"
echo -e " • Health Check Endpoint:     ${CYAN}http://localhost:8080/health/ready${NC}"
echo -e " • Prometheus Metrics:        ${CYAN}http://localhost:8080/metrics${NC}"
echo -e " • NATS JetStream Monitor:    ${CYAN}http://localhost:8222${NC}"
echo -e " • PgBouncer Pool Port:       ${CYAN}localhost:6432${NC}"
echo -e "${GREEN}======================================================${NC}"
