create_env_files() {

  echo ""
  echo "📝 Paste ENV content below."
  echo "Press CTRL+D when finished."
  echo ""

  TMP_ENV=$(mktemp)
  cat > "$TMP_ENV"

  if [[ "$APP_TYPE" == "next" ]]; then

    cp "$TMP_ENV" .env
    echo "✅ Created .env in root"

  else

    mkdir -p env
    cp "$TMP_ENV" env/.env
    cp "$TMP_ENV" env/.env.production
    cp "$TMP_ENV" env/.env.development

    echo "✅ Created env/.env files"

  fi

  rm "$TMP_ENV"
}