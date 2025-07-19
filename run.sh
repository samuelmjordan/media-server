#!/bin/bash
set -e

dune build
docker compose up -d
sleep 2

for migration in migrations/*.sql; do
    filename=$(basename "$migration" .sql)
    if ! psql -h localhost -U youruser -d yourdb -tAc "SELECT 1 FROM schema_migrations WHERE version='$filename'" 2>/dev/null | grep -q 1; then
        echo "running $migration"
        psql -h localhost -U youruser -d yourdb -f "$migration"
        psql -h localhost -U youruser -d yourdb -c "INSERT INTO schema_migrations (version) VALUES ('$filename')"
    fi
done

dune exec nautilus