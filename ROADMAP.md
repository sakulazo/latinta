# ROADMAP — Latinta

> Tienda online de artículos de regalo.
> Stack: **Medusa** (backend headless) · **Next.js** (storefront) · **Stripe** (pagos) · **PostgreSQL** (base de datos) · **pnpm** (monorepo)

**Cómo leer este documento:**

- Este archivo es el estado real del proyecto. Siempre refleja lo que está hecho y lo que falta.
- Cada fase se desglosa en tareas con checkboxes `- [ ]`. Marcar al completar.
- El detalle técnico profundo de una feature concreta no va aquí: va en su issue o spec (usando el flujo `sdd` de OpenCode cuando sea compleja).
- `AGENTS.md` define *cómo* trabajar (comandos, límites). Este archivo define *qué* falta.

---

## Estado general

| Fase | Estado |
|---|---|
| 0. Setup del monorepo e infraestructura | ✅ Completada |
| 1. Backend Medusa | ⬜ No iniciada |
| 2. Pagos con Stripe | ⬜ No iniciada |
| 3. Storefront Next.js | ⬜ No iniciada |
| 4. Admin y personalización | ⬜ No iniciada |
| 5. QA y testing | ⬜ No iniciada |
| 6. Deployment y producción | ⬜ No iniciada |
| 7. Post-lanzamiento | ⬜ No iniciada |

---

## Fase 0 — Setup del monorepo e infraestructura

- [x] Inicializar monorepo pnpm + Turborepo (`pnpm-workspace.yaml`, `turbo.json`)
- [x] Crear estructura: `apps/backend` (Medusa) y `apps/storefront` (Next.js)
- [x] Scaffold del backend Medusa + storefront (`create-medusa-app@latest --with-nextjs-starter`)
- [x] PostgreSQL local + `DATABASE_URL` en el `.env` del backend
  - Sin root/sudo ni Docker en esta máquina → PostgreSQL 17 **rootless** en `~/.local/pgsql`,
    DB `latinta`, gestionado con `./scripts/pg.sh`. Se descartó docker-compose para dev local.
- [x] `.env` por app + `.env.template` documentado; `.env`/`.env.local` gitignored
- [x] Medusa: migraciones + seed inicial ejecutados; usuario admin creado
- [x] Scripts raíz: `pnpm dev`, `pnpm build`, `pnpm lint`, `pnpm typecheck`
- [ ] CI básico (GitHub Actions): lint + typecheck en PR (pendiente: requiere remoto en GitHub)

**Criterio de salida:** `pnpm dev` levanta backend + storefront sin errores y el admin de Medusa responde.
**Verificado:** backend en `:9000` (admin en `/app` HTTP 200, Store API con precios EUR) y storefront en `:8000`
(redirect a `/es`, página de producto renderizando "Medusa Sweatshirt").

---

## Fase 1 — Backend Medusa (catálogo y comercio base)

- [ ] Región y moneda de venta configuradas
- [ ] Definir taxonomía de productos de regalo (categorías, colecciones)
- [ ] Seed script: productos, precios, imágenes, stock inicial
- [ ] Tipos de envío (shipping options) configurados
- [ ] Flujo de carrito: crear, añadir/quitar items, actualizar cantidades (API)
- [ ] Flujo de pedidos: checkout → orden creada
- [ ] Customer/authentication: registro, login, historial de pedidos
- [ ] Correos transaccionales (confirmación de pedido) vía Resend/Postmark u otro provider

**Criterio de salida:** se puede simular una compra completa vía API/admin, de producto a orden.

---

## Fase 2 — Pagos con Stripe

- [ ] `STRIPE_API_KEY` / `STRIPE_SECRET_KEY` y `STRIPE_WEBHOOK_SECRET` configurados en backend
- [ ] Plugin de pagos Medusa + Stripe instalado y activo
- [ ] Checkout con Stripe (tarjetas) en el storefront
- [ ] Webhook endpoint registrado en Stripe (evento `checkout.session.completed`, `payment_intent.*`)
- [ ] Manejo de eventos de webhook: pago completado → orden confirmada; pago fallido → estado acorde
- [ ] Modo test completo: compra exitosa, pago rechazado, reembolso
- [ ] (Post-lanzamiento) Añadir métodos locales: Bizum / Apple Pay / Google Pay

**Criterio de salida:** compra de prueba con tarjeta de Stripe test-mode pasa de punta a punta y el webhook actualiza el estado del pedido.

---

## Fase 3 — Storefront Next.js

- [ ] Página home (destacados, categorías)
- [ ] Listado de categorías y productos (SSR/ISR con el Store API de Medusa)
- [ ] Página de detalle de producto (variantes, precios, imágenes, stock)
- [ ] Carrito (cliente y persistencia)
- [ ] Checkout (dirección → envío → pago Stripe)
- [ ] Páginas legales: privacidad, cookies, devoluciones, términos
- [ ] Páginas informativas: contacto, envíos y plazos, FAQ
- [ ] SEO: metadata, sitemap, Open Graph, structured data de producto
- [ ] Analytics: Plausible o GA4 (consentimiento si aplica)

**Criterio de salida:** navegación completa catálogo → carrito → checkout de prueba sin tocar código intermedio.

---

## Fase 4 — Admin y personalización Medusa

- [ ] Workflow de fulfillment (preparación → envío → entrega, con número de seguimiento)
- [ ] Gestión de devoluciones/cambios (feature clave para tienda de regalos)
- [ ] Descuentos y códigos promocionales (temporadas: Navidad, Reyes, etc.)
- [ ] Personalización del admin: custom widgets si se necesita (ej. notas de regalo)
- [ ] (Opcional) Nota de regalo por pedido: campo custom + método custom endpoint

**Criterio de salida:** el operador puede gestionar pedidos, envíos y devoluciones desde el admin.

---

## Fase 5 — QA y testing

- [ ] Tests unitarios de lógica crítica (totals, custom modules si los hay)
- [ ] Tests de flujos clave con `medusa-test-utils` o Playwright (compra end-to-end)
- [ ] Pruebas manuales en móvil real (catálogo, checkout, pagos)
- [ ] Lighthouse en storefront: performance ≥ 90, a11y sin errores críticos
- [ ] Revisión de seguridad: keys fuera del repo, rate limiting en API pública, validación de inputs
- [ ] Estados de error: 404, error de pago, stock agotado durante checkout

**Criterio de salida:** suite verde + checklist manual completado.

---

## Fase 6 — Deployment y producción

- [ ] Elegir hosting: Medusa Cloud (recomendado) vs VPS self-managed
- [ ] Base de datos producción (Neon/Supabase/RDS) + backups automáticos
- [ ] Variables de entorno de producción (Stripe **live** keys)
- [ ] Dominio + SSL (certbot o el managed del hosting)
- [ ] Webhook de Stripe apuntando al dominio de producción
- [ ] Storefront en Vercel/Netlify (o el mismo VPS)
- [ ] Deploy inicial + smoke test de compra real de bajo importe

**Criterio de salida:** una compra real se completa en producción de punta a punta.

---

## Fase 7 — Post-lanzamiento

- [ ] Monitoreo: uptime (UptimeRobot/Better Stack) + errores (Sentry)
- [ ] Backends verificados: backup y restore de BD probado una vez
- [ ] Email transaccional verificado en producción (no va a spam)
- [ ] Iterar según feedback: wishlist, envoltorio de regalo, envío express, tarjeta regalo

---

## Convenciones

- **Rama principal siempre verde:** `main` = `pnpm lint` + `pnpm typecheck` + build pasan.
- **Commits:** convención Conventional Commits (`feat:`, `fix:`, `chore:`).
- **Features grandes:** antes de implementar, generar spec/design/tasks con el flujo `sdd` (spec-driven development).
- **Actualizar este archivo:** cada sesión de trabajo que cierre tareas marca checkboxes y actualiza la tabla de estado.
