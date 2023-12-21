#!/usr/bin/env bash

set -e

say_info() {
  printf '%s\n' "$@" >&2
}

say_err() {
  echo "ERROR: $*" >&2
}

say_info "Creating grafana read only user"

if [ -z "$GRAFANA_DB_PASSWORD" ] || [ -z "$GRAFANA_DB_USER" ]; then
    say_err "GRAFANA_DB_PASSWORD or GRAFANA_DB_USER environment variable not set."
    exit 1
fi

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    create role $GRAFANA_DB_USER with login password '$GRAFANA_DB_PASSWORD';
    grant pg_read_all_data to $GRAFANA_DB_USER;
    alter role grafana_readonly set search_path='timescale';
EOSQL

say_info "Grafana read only user $GRAFANA_DB_USER created"
