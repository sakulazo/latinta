# Latinta

Tienda online de artículos de regalo.

Stack: **Medusa** (backend headless) · **Next.js** (storefront) · **PostgreSQL** (base de datos) · **Stripe** (pagos, Fase 2).

Monorepo Turborepo + pnpm:

```
apps/
├── backend/     # Medusa v2 (@dtc/backend) — API + admin
└── storefront/  # Next.js Starter (@dtc/storefront)
```

El plan por fases y el estado del proyecto están en [ROADMAP.md](./ROADMAP.md).
Las convenciones y comandos para agentes están en [AGENTS.md](./AGENTS.md).

## Requisitos

- Node.js >= 22.22 (probado con 24.x)
- pnpm 11 (`packageManager: pnpm@11.18.0`)
- PostgreSQL 17. En esta máquina corre **rootless** (sin root/Docker) desde `~/.local/pgsql`;
  los binarios de PostgreSQL se obtienen del paquete npm `@embedded-postgres/linux-x64`.

## Puesta en marcha

```bash
# 1. Dependencias
pnpm install

# 2. Base de datos (rootless)
./scripts/pg.sh start        # start | stop | status | url | log

# 3. Variables de entorno (una vez)
cp apps/backend/.env.template apps/backend/.env
cp apps/storefront/.env.template apps/storefront/.env.local
# Rellena NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY (admin > Settings > API Key Management)

# 4. Migraciones (solo la primera vez o tras cambios de esquema)
cd apps/backend && pnpm exec medusa db:migrate && cd -

# 5. Desarrollo
pnpm dev                     # backend :9000 + storefront :8000
```

- Backend / Admin: http://localhost:9000/app
- Storefront: http://localhost:8000

## Comandos

```bash
pnpm dev            # backend (:9000) + storefront (:8000)
pnpm backend:dev    # solo backend
pnpm storefront:dev # solo storefront
pnpm build          # build de todas las apps
pnpm lint           # lint (turbo)
pnpm typecheck      # tsc --noEmit (turbo)
pnpm test           # tests del backend
```

## Credenciales de desarrollo

- Admin Medusa: `admin@latinta.local` / `Latinta2026!` (cambiar antes de producción)
- Región por defecto: `Europe` (EUR), país `es`
