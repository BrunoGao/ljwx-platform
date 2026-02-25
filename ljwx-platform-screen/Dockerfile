# syntax=docker/dockerfile:1

# ── Stage 1: build ─────────────────────────────────────────────────────────────
FROM node:22-alpine AS builder

RUN npm install -g pnpm@10.30.1 --quiet

WORKDIR /app

# Copy workspace manifests first (layer-cache friendly)
COPY pnpm-workspace.yaml package.json pnpm-lock.yaml ./
COPY packages/shared/package.json packages/shared/
COPY ljwx-platform-screen/package.json ljwx-platform-screen/

# Install all workspace deps (frozen lockfile)
RUN pnpm install --frozen-lockfile

# Copy source
COPY packages/shared/ packages/shared/
COPY ljwx-platform-screen/ ljwx-platform-screen/

# Build shared package, then screen
RUN pnpm run build:shared
RUN pnpm --filter ljwx-platform-screen build

# ── Stage 2: serve ─────────────────────────────────────────────────────────────
FROM nginx:1.27-alpine AS runtime

# Default nginx config (overridable via ConfigMap mount in k8s)
RUN printf 'server {\n\
  listen 80;\n\
  server_name _;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
\n\
  location / {\n\
    try_files $uri $uri/ /index.html;\n\
  }\n\
}\n' > /etc/nginx/conf.d/default.conf

COPY --from=builder /app/ljwx-platform-screen/dist /usr/share/nginx/html

EXPOSE 80
