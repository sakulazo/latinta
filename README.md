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

**Con Docker (Opción A):** solo Docker (Docker Desktop con integración WSL2, o Docker Engine). Nada más.

**Sin Docker (Opción B):**
- Node.js >= 22.22 (probado con 24.x)
- pnpm 11 (`packageManager: pnpm@11.18.0`)
- PostgreSQL 17. En esta máquina corre **rootless** (sin root/Docker) desde `~/.local/pgsql`;
  los binarios de PostgreSQL se obtienen del paquete npm `@embedded-postgres/linux-x64`.

## Puesta en marcha

### Opción A — Docker (nada que instalar en el runtime) · recomendada

Solo necesitas Docker (p. ej. Docker Desktop en Windows con integración WSL2).
Todo lo demás (Node, pnpm, Medusa, Next, Postgres) vive en contenedores.

```bash
docker compose up --build
```

- Admin Medusa: http://localhost:9000/app
- Storefront: http://localhost:8000

El backend aplica migraciones, crea el usuario admin y publica la publishable API
key automáticamente; el storefront la consume al arrancar. Para sobrescribir
valores (puertos, credenciales, secretos) copia `.env.example` → `.env`.

```bash
docker compose logs -f backend     # logs
docker compose down                # parar (mantiene la BD)
docker compose down -v             # parar y borrar la BD
```

> Si tienes el PostgreSQL rootless levantado (`./scripts/pg.sh status`), el puerto
> 5432 choca con el contenedor. Páralo (`./scripts/pg.sh stop`) o cambia
> `POSTGRES_PORT` en el `.env` de la raíz. La primera build tarda: instala todas
> las dependencias dentro de la imagen.

### Opción B — Local sin contenedores

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
