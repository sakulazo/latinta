#!/usr/bin/env bash
#
# Rootless PostgreSQL 17 helper for local development.
#
# This machine has no root/sudo and no Docker, so PostgreSQL runs as a plain
# user process using prebuilt binaries extracted to ~/.local/pgsql.
#
# Usage: ./scripts/pg.sh {start|stop|restart|status|log|psql|url}
#
set -euo pipefail

PGHOME="${PGHOME:-$HOME/.local/pgsql}"
PGDATA="${PGDATA:-$HOME/.local/share/latinta/pgdata}"
PGPORT="${PGPORT:-5432}"
PGLOG="$HOME/.local/share/latinta/postgres.log"

export LD_LIBRARY_PATH="$PGHOME/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

BIN="$PGHOME/bin"

require_bin() {
  if [ ! -x "$BIN/pg_ctl" ]; then
    echo "ERROR: no se encuentra $BIN/pg_ctl." >&2
    echo "Los binarios de PostgreSQL deberian estar en $PGHOME (ver AGENTS.md)." >&2
    exit 1
  fi
}

cmd_start() {
  require_bin
  if "$BIN/pg_ctl" -D "$PGDATA" status >/dev/null 2>&1; then
    echo "PostgreSQL ya esta corriendo (puerto $PGPORT)."
    return 0
  fi
  mkdir -p "$(dirname "$PGLOG")"
  "$BIN/pg_ctl" -D "$PGDATA" -l "$PGLOG" -o "-p $PGPORT" -w start
}

cmd_stop() {
  require_bin
  if ! "$BIN/pg_ctl" -D "$PGDATA" status >/dev/null 2>&1; then
    echo "PostgreSQL no esta corriendo."
    return 0
  fi
  "$BIN/pg_ctl" -D "$PGDATA" -m fast -w stop
}

cmd_status() {
  require_bin
  "$BIN/pg_ctl" -D "$PGDATA" status || true
}

cmd_log() {
  tail -n "${2:-50}" -f "$PGLOG"
}

cmd_psql() {
  if ! command -v psql >/dev/null 2>&1; then
    echo "psql no esta instalado (los binarios rootless no incluyen el cliente)." >&2
    echo "Usa el driver 'pg' de Node o el admin de Medusa para consultar la base." >&2
    exit 1
  fi
  psql "postgres://latinta@127.0.0.1:$PGPORT/latinta" "$@"
}

cmd_url() {
  echo "postgres://latinta@127.0.0.1:$PGPORT/latinta"
}

case "${1:-}" in
  start)   cmd_start ;;
  stop)    cmd_stop ;;
  restart) cmd_stop; cmd_start ;;
  status)  cmd_status ;;
  log)     cmd_log "$@" ;;
  psql)    shift; cmd_psql "$@" ;;
  url)     cmd_url ;;
  *)
    echo "Uso: $0 {start|stop|restart|status|log|psql|url}" >&2
    exit 1
    ;;
esac
