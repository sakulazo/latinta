# AGENTS.md

## Project
- Gift e-commerce (tienda online de artículos de regalo)
- Stack: Medusa (headless commerce backend) + Next.js (storefront) + Stripe (payments) + PostgreSQL (database)
- Monorepo Turborepo: `apps/backend` (Medusa) + `apps/storefront` (Next.js). Ver `ROADMAP.md` para el plan por fases.

## Directory Structure

```text
.
├── apps/
│   ├── backend/                  # Medusa application (@dtc/backend)
│   │   ├── medusa-config.ts      # Medusa config: DB URL, CORS, secrets, modules
│   │   ├── integration-tests/    # setup.js (Jest setupFiles) and http/*.spec.ts suites
│   │   └── src/
│   │       ├── admin/            # Admin dashboard extensions (widgets/, i18n/, routes)
│   │       ├── api/              # API routes: api/store/*, api/admin/* (file-based)
│   │       ├── jobs/             # Scheduled jobs
│   │       ├── links/            # Module links between modules
│   │       ├── migration-scripts/# Data migration scripts (e.g. initial-data-seed.ts)
│   │       ├── modules/          # Custom modules (service + models + migrations)
│   │       ├── subscribers/      # Event subscribers
│   │       └── workflows/        # Workflows and workflow steps
│   └── storefront/               # Next.js storefront (@dtc/storefront)
├── eslint.config.ts              # Root ESLint: @medusajs/eslint-plugin recommended
├── turbo.json                    # Task graph: build, dev, start, lint, test, seed
```

Each app can have its own nested `AGENTS.md`; agents read the nearest one in the directory tree, so put app-specific context there rather than expanding this file.

## Toolchain
- Package manager: **pnpm** (`packageManager: pnpm@11.18.0`). It is a pnpm/Turborepo workspace. Never introduce a second lockfile.
- Install dependencies inside the app that needs them: `cd apps/backend && pnpm add <pkg>`.
- pnpm 11 requires build scripts to be approved explicitly; they live under `allowBuilds` in `pnpm-workspace.yaml`, not in `package.json`.

## Commands
`package.json` scripts are the source of truth. Run from the repo root unless noted.

### Docker (dev con hot reload)
Nada que instalar en el runtime salvo Docker. Levanta Postgres + backend + storefront:
```bash
docker compose up --build      # Admin: http://localhost:9000/app | Storefront: http://localhost:8000
docker compose logs -f backend
docker compose down            # parar (conserva la BD)   |   down -v para borrarla
```
`start.sh` (backend) corre migraciones, crea el admin si falta y publica la publishable key en el volumen `shared`; `start-storefront.sh` la consume. Los secretos/puertos se sobrescriben con un `.env` en la raíz (ver `.env.example`).

### Development (local, sin Docker)
```bash
pnpm dev                # all apps
pnpm backend:dev        # backend only (http://localhost:9000, admin at /app)
pnpm storefront:dev     # storefront only (http://localhost:8000)
```

### Build / Lint / Test
```bash
pnpm build              # all apps
pnpm lint               # all apps via turbo
pnpm test               # all test tasks via turbo (backend only)
cd apps/backend && pnpm run test:unit
cd apps/backend && pnpm run test:integration:modules
cd apps/backend && pnpm run test:integration:http
```

### Database
```bash
cd apps/backend
pnpm exec medusa db:generate <module-name>   # generate migrations for a custom module
pnpm exec medusa db:migrate                  # run migrations
pnpm exec medusa user -e admin@test.com -p supersecret
```

## Local prerequisites
- **PostgreSQL** must be running before starting Medusa. Two supported flows:
  - **Docker (recomendado):** `docker compose up` levanta Postgres 17 + backend + storefront. Nada se instala en el runtime.
  - **Local rootless:** este equipo no tiene root/Docker, así que PostgreSQL 17 corre como proceso de usuario desde `~/.local/pgsql` con datos en `~/.local/share/latinta/pgdata`. Gestiónalo con `./scripts/pg.sh {start|stop|status|log}`.
    - Conexión local: `postgres://latinta@127.0.0.1:5432/latinta` (`DATABASE_URL` en `apps/backend/.env`).
    - Ojo: si usas ambos flujos a la vez, los puertos `5432` chocan; usa uno u otro.
- **SSL con Postgres en Docker:** Medusa activa SSL automáticamente cuando el host del `DATABASE_URL` no es `localhost`/`127.0.0.1` (ver `getDefaultDriverOptions` en `@medusajs/utils`). En Docker el host es `postgres`, así que hay que desactivarlo con `?sslmode=disable` (ya incluido en `compose.yaml`). Sin ello, `db:migrate` falla con "Could not connect to the database while running migrations. The connection timed out after 10 seconds". Alternativa: `databaseDriverOptions: { ssl: false, sslmode: "disable" }` en `medusa-config.ts`.
- **URL del backend en el storefront:** `NEXT_PUBLIC_MEDUSA_BACKEND_URL` es la del navegador; `MEDUSA_BACKEND_URL` (sin `NEXT_PUBLIC_`) es la interna para SSR/middleware. En Docker: `http://localhost:9000` y `http://backend:9000` respectivamente. No expongas la URL interna al cliente.
- **Redis is not required.** The backend logs "redisUrl not found. A fake redis instance will be used" and uses in-memory cache/locking/event-bus. `REDIS_URL` in `.env` is unused by the default `medusa-config.ts`.
- **Stripe test keys** (later, Fase 2): `STRIPE_API_KEY` / `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` in the backend. Configure the webhook endpoint in Stripe for local dev.
- Env files: `apps/backend/.env` and `apps/storefront/.env.local`. Templates: `apps/backend/.env.template` and `apps/storefront/.env.local` (keep keys documented there, never commit real `.env` files).

## Code Style
- **The backend must satisfy `@medusajs/eslint-plugin`'s recommended config** (`eslint.config.ts`). Its rules encode Medusa framework requirements — correct route/workflow/module shapes, not just cosmetics — so a lint failure usually means the code is actually wrong. Never disable a `@medusajs/*` rule to make lint pass; fix the code.
- No semicolons. Double quotes, 2-space indent.
- Files: kebab-case. Types/classes: PascalCase. Functions/variables: camelCase. DB columns: snake_case.
- No emojis in code, comments, or commit messages.

## Conventions
- **Backend routing is file-based.** A store endpoint is `src/api/store/<path>/route.ts` exporting `GET`/`POST`/etc. Don't add a router or register routes manually.
- **Business logic belongs in workflows**, not in route handlers. Routes resolve and run a workflow; workflows compose steps.
- Adding a task to `turbo.json` requires declaring its `outputs`, or Turbo will cache nothing/the wrong thing.

## Boundaries & gotchas
- Medusa backend and Next.js storefront are separate apps. Do not import server-only Medusa code into the storefront.
- After pulling schema changes, run migrations before starting dev (`cd apps/backend && pnpm exec medusa db:migrate`).
- Never commit, print, or copy secret values out of `.env` / `.env.local`.

## Common Mistakes
- Assuming a package manager instead of detecting it, or running a command that creates a second lockfile.
- Installing a dependency at the root instead of inside the app that needs it (`cd apps/backend && pnpm add <pkg>`).
- Editing a custom module's model without running `pnpm exec medusa db:generate <module>` — the migration is missing and the change silently never applies.
- Writing raw SQL or importing DB clients directly in the backend instead of going through module services / workflows.
- Calling the Medusa API from the storefront without `NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY`; requests fail with a publishable-key error, not an obvious 401.
- Running the test task without a reachable PostgreSQL — integration suites need a live DB.
- Silencing `@medusajs/*` ESLint rules instead of fixing the underlying pattern.

## Off-Limits
- `apps/backend/.medusa/`, `.next/`, `dist/`, `out/`, `.turbo/` — build output, excluded from the workspace and regenerated.
- The lockfile (`pnpm-lock.yaml`) — never hand-edit or delete; change it only as a side effect of a package manager command.
- `.env` / `.env.local` — never commit secrets. Edit the templates instead when documenting a new variable.
- Existing migrations in `src/modules/*/migrations/` — add a new migration rather than rewriting one that may already have run.
- Don't run destructive DB commands (drops, reset flags) against the user's database without explicit confirmation.
