#!/bin/sh
# Storefront entrypoint (dev with hot reload).
# Resolves the publishable API key the backend generated, then starts `next dev`.
set -e

cd /server/apps/storefront

# Prefer an explicitly provided key; otherwise read the one the backend published.
if [ -z "${NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY:-}" ] && [ -f /shared/publishable-key ]; then
  NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY="$(cat /shared/publishable-key)"
  export NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY
fi

if [ -z "${NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY:-}" ]; then
  echo "[storefront] AVISO: sin publishable key; el catalogo puede fallar."
  echo "[storefront] Definela en NEXT_PUBLIC_MEDUSA_PUBLISHABLE_KEY o reinicia tras arrancar el backend."
fi

echo "[storefront] Arrancando Next.js (dev) en http://localhost:8000 ..."
exec pnpm dev
