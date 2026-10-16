# Single image for both the Medusa backend and the Next.js storefront.
# The storefront service overrides the entrypoint (see compose.yaml).
FROM node:22-bookworm-slim

# pnpm via corepack (version pinned by the root packageManager field)
ENV PNPM_HOME=/pnpm
ENV PATH=$PNPM_HOME:$PATH
RUN corepack enable && corepack prepare pnpm@11.18.0 --activate && mkdir -p "$PNPM_HOME"

# /server instead of /app: avoids path conflicts with the Medusa Admin customizations
WORKDIR /server

# Install dependencies first so the layer is cached unless manifests change.
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml turbo.json .npmrc ./
COPY apps/backend/package.json ./apps/backend/
COPY apps/storefront/package.json ./apps/storefront/

RUN pnpm install --frozen-lockfile

# Then the rest of the source (overridden at runtime by the bind mount in dev).
COPY . .

# 9000: backend + admin, 8000: storefront
EXPOSE 9000 8000

CMD ["pnpm", "dev"]
