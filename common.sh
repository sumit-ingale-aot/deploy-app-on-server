#!/usr/bin/env bash
set -e

###################################
# Load NVM (if exists)
###################################
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
elif [ -s "/usr/local/bin/nvm" ]; then
    . "/usr/local/bin/nvm"
fi

###################################
# Helper: Set or replace KEY=value in an env file
# Usage: set_env_key path/to/.env KEY value
###################################
set_env_key() {
  local file=$1
  local key=$2
  local value=$3
  local tmp

  mkdir -p "$(dirname "$file")"
  touch "$file"

  if grep -q "^${key}=" "$file"; then
    tmp=$(mktemp)
    while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" == "${key}="* ]]; then
        echo "${key}=${value}"
      else
        echo "$line"
      fi
    done < "$file" > "$tmp"
    mv "$tmp" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

###################################
# Helper: Ask with Default
# Usage: ask_with_default "Prompt" "default_val" VAR_NAME
###################################
ask_with_default() {
    local prompt=$1
    local default=$2
    local var_name=$3
    local input

    read -p "❓ $prompt [$default]: " input
    if [[ -z "$input" ]]; then
        eval "$var_name=\"$default\""
    else
        eval "$var_name=\"$input\""
    fi
}

###################################
# Node Selection (nvm + system)
###################################
select_node() {
  NODE_OPTIONS=()
  NODE_SOURCE=()

  if command -v nvm >/dev/null 2>&1; then
    mapfile -t NVM_VERSIONS < <(
      nvm ls --bare 2>/dev/null | sed 's/^v//' | sort -V
    )
    for v in "${NVM_VERSIONS[@]}"; do
      NODE_OPTIONS+=("$v")
      NODE_SOURCE+=("nvm")
    done
  fi

  if command -v node >/dev/null 2>&1; then
    SYS_NODE_VERSION=$(node -v | sed 's/^v//')
    NODE_OPTIONS+=("system ($SYS_NODE_VERSION)")
    NODE_SOURCE+=("system")
  fi

  NODE_OPTIONS+=("Other")
  NODE_SOURCE+=("other")

  echo "👉 Select Node Version"
  select NODE_CHOICE in "${NODE_OPTIONS[@]}"; do
    [[ -n "$NODE_CHOICE" ]] && break
    echo "❌ Invalid choice"
  done

  INDEX=$((REPLY - 1))
  SOURCE="${NODE_SOURCE[$INDEX]}"

  if [[ "$SOURCE" == "nvm" ]]; then
    nvm use "$NODE_CHOICE"
  elif [[ "$SOURCE" == "system" ]]; then
    echo "⚠️ Using system Node $(node -v)"
  else
    read -p "Enter Node version to install via nvm: " VERSION
    nvm install "$VERSION"
    nvm use "$VERSION"
  fi

  echo "✅ Active Node: $(node -v)"
}

###################################
# Package Manager Selection (ALWAYS ASK)
###################################
select_package_manager() {

  echo ""
  echo "👉 Select Package Manager"

  PM_OPTIONS=("npm")

  command -v yarn >/dev/null && PM_OPTIONS+=("yarn")
  command -v pnpm >/dev/null && PM_OPTIONS+=("pnpm")

  PM_OPTIONS+=("Install yarn" "Install pnpm")

  select PM in "${PM_OPTIONS[@]}"; do
    case "$PM" in
      npm)
        PACKAGE_MANAGER="npm"
        break
        ;;
      yarn)
        PACKAGE_MANAGER="yarn"
        break
        ;;
      pnpm)
        PACKAGE_MANAGER="pnpm"
        break
        ;;
      "Install yarn")
        npm install -g yarn
        PACKAGE_MANAGER="yarn"
        break
        ;;
      "Install pnpm")
        npm install -g pnpm
        PACKAGE_MANAGER="pnpm"
        break
        ;;
      *)
        echo "❌ Invalid choice"
        ;;
    esac
  done

  echo "✅ Using $PACKAGE_MANAGER"
  export PACKAGE_MANAGER
}


###################################
# Find Next Available Port
# Usage: get_next_port 3000
###################################
get_next_port() {
  local START_PORT=$1
  local PORT=$START_PORT

  while true; do
    if ! ss -tuln | awk '{print $5}' | grep -q ":$PORT$"; then
      echo "$PORT"
      return
    fi
    PORT=$((PORT + 1))
  done
}

###################################
# Ask whether to enable SSL (input phase)
# Usage: ask_ssl example.com
###################################
ask_ssl() {
  local DOMAIN=$1

  echo ""
  read -p "🔐 Enable SSL for $DOMAIN? (y/n): " ENABLE_SSL
  export ENABLE_SSL
}

###################################
# Setup SSL via Certbot (work phase)
# Usage: setup_ssl example.com
###################################
setup_ssl() {
  local DOMAIN=$1

  if [[ "$ENABLE_SSL" =~ ^[Yy]$ ]]; then
    echo "🔐 Setting up SSL for $DOMAIN..."

    if ! command -v certbot >/dev/null; then
      echo "📦 Installing certbot..."
      sudo apt update
      sudo apt install -y certbot python3-certbot-nginx
    fi

    sudo certbot --nginx -d "$DOMAIN"

    echo "✅ SSL enabled for $DOMAIN"
  else
    echo "⏭️ Skipping SSL setup"
  fi
}


###################################
# Clone Repository into current dir
###################################
clone_repo() {

  read -p "🔗 Enter Git repository URL: " REPO

  if [ -z "$REPO" ]; then
    echo "❌ Repo URL required"
    exit 1
  fi

  if [ -f "package.json" ]; then
    echo "⚠️ package.json already exists, assuming project already present."
    return
  fi

  echo "📥 Cloning repository..."
  git clone "$REPO" . || { echo "❌ Clone failed"; exit 1; }

  echo "✅ Repo cloned"
}

