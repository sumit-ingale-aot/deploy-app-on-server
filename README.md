# Deploy App on Server

Interactive setup for NestJS and Next.js apps: clone, env, Node, Nginx, SSL, install, build, and PM2.

Scripts live in `/var/www/deploy`. Run `deploy-app` from the **app directory** (not from `deploy/`), because the repo is cloned into the current working directory.

## Install on the server

Copy the scripts into `/var/www/deploy` if they are not already there, then:

```bash
cd /var/www/deploy
chmod +x setup.sh nest-setup.sh next-setup.sh common.sh env-setup.sh
ln -sf /var/www/deploy/setup.sh /usr/local/bin/deploy-app
```

After that, `deploy-app` is available from any directory.

## Deploy an app

```bash
mkdir -p /var/www/my-app
cd /var/www/my-app
deploy-app
```

You will be asked for everything up front (app type, repo URL, env paste, Node, package manager, install flags, domain, SSL). Nginx, Certbot, install, build, and PM2 then run without further prompts.

## What it does

1. Select NestJS or Next.js
2. Clone the repo into the current directory
3. Create env files (Next: `.env`; Nest: `env/.env`, `env/.env.production`, `env/.env.development`)
4. Select Node version and package manager
5. Ask for install flags and domain (Nginx config name = domain, root = current dir)
6. Auto-pick a free port (Next from 3000, Nest from 8000). Nest also sets `APP_PORT` in its env files
7. Write Nginx, optional SSL, install, build, start with PM2
