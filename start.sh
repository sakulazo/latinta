#!/bin/sh
# Backend entrypoint (dev with hot reload).
#   1. wait for PostgreSQL
#   2. run migrations + initial seed
#   3. ensure the admin user exists
#   4. publish the generated publishable API key for the storefront
#   5. start `medusa develop`
set -e

cd /server/apps/backend

# Defaults de desarrollo (compose los sobreescribe con las variables de entorno).
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@latinta.local}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-Latinta2026!}"
export ADMIN_EMAIL ADMIN_PASSWORD

echo "[backend] Esperando a PostgreSQL..."
until node -e "const{Client}=require('pg');const c=new Client({connectionString:process.env.DATABASE_URL});c.connect().then(()=>c.end()).then(()=>process.exit(0)).catch(()=>process.exit(1))" 2>/dev/null; do
  sleep 2
done

echo "[backend] Ejecutando migraciones y seed inicial..."
pnpm exec medusa db:migrate

echo "[backend] Asegurando usuario admin (${ADMIN_EMAIL})..."
# `medusa user` falla si el usuario ya existe; es idempotente a proposito.
pnpm exec medusa user -e "${ADMIN_EMAIL}" -p "${ADMIN_PASSWORD}" \
  || echo "[backend] El usuario admin ya existe (o no se pudo crear); continuo."

echo "[backend] Publicando publishable API key para el storefront..."
mkdir -p /shared
if node /server/scripts/print-publishable-key.js > /shared/publishable-key 2>/dev/null; then
  echo "[backend] Publishable key escrita en /shared/publishable-key"
else
  echo "[backend] AVISO: no se pudo obtener la publishable key."
fi

echo "[backend] Arrancando Medusa (dev) en http://localhost:9000 ..."
exec pnpm dev
