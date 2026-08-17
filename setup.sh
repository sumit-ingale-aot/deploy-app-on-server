#!/usr/bin/env bash
set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

echo "🚀 Universal Node App Auto Setup"
echo "================================"

source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/env-setup.sh"

# ----------------------------
# Select App Type
# ----------------------------
echo "👉 Select App Type"
select TYPE in "NestJS API" "Next.js App"; do
  case $REPLY in
    1) APP_TYPE="nest"; break ;;
    2) APP_TYPE="next"; break ;;
    *) echo "❌ Invalid choice";;
  esac
done

# ----------------------------
# CLONE REPO FIRST
# ----------------------------
clone_repo

# ----------------------------
# CREATE ENV FILES
# ----------------------------
create_env_files

# ----------------------------
# THEN NODE + PM
# ----------------------------
select_node
select_package_manager

# ----------------------------
# INSTALL FLAGS
# ----------------------------
echo ""
read -p "❓ Install flags (e.g. --legacy-peer-deps): " INSTALL_FLAGS

# ----------------------------
# DOMAIN (config name = domain, root = cwd)
# ----------------------------
if [[ "$APP_TYPE" == "nest" ]]; then
  ask_with_default "Domain (server_name)" "api.example.com" SERVER_NAME
else
  ask_with_default "Domain (server_name)" "app.example.com" SERVER_NAME
fi

CONF_NAME="$SERVER_NAME"
ROOT_PATH="$(pwd)"
UPSTREAM="${SERVER_NAME}_upstream"

echo "✅ Nginx config: $CONF_NAME"
echo "✅ Root path: $ROOT_PATH"
if [[ "$APP_TYPE" == "nest" ]]; then
  echo "✅ Upstream: $UPSTREAM"
fi

# ----------------------------
# AUTO PORT (+ Nest APP_PORT)
# ----------------------------
if [[ "$APP_TYPE" == "nest" ]]; then
  PORT=$(get_next_port 8000)
  echo "🚀 Auto-selected NestJS port: $PORT"
  set_env_key env/.env APP_PORT "$PORT"
  set_env_key env/.env.production APP_PORT "$PORT"
  set_env_key env/.env.development APP_PORT "$PORT"
  echo "✅ Set APP_PORT=$PORT in env files"
else
  PORT=$(get_next_port 3000)
  echo "🚀 Auto-selected Next.js port: $PORT"
fi

# ----------------------------
# SSL PROMPT
# ----------------------------
ask_ssl "$SERVER_NAME"

export APP_TYPE PACKAGE_MANAGER INSTALL_FLAGS SERVER_NAME CONF_NAME ROOT_PATH UPSTREAM PORT ENABLE_SSL

# ----------------------------
# Run Setup (same shell — keep nvm + PACKAGE_MANAGER)
# ----------------------------
if [[ "$APP_TYPE" == "nest" ]]; then
  source "$SCRIPT_DIR/nest-setup.sh"
else
  source "$SCRIPT_DIR/next-setup.sh"
fi
