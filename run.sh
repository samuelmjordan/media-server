#!/bin/bash
set -e

dune build
docker compose up -d
sleep 1

# use the postgres container to run psql
PSQL="docker exec -i $(docker compose ps -q postgres) psql -U default -d mydatabase"

# create migration tracking table
echo "CREATE TABLE IF NOT EXISTS schema_migrations (version TEXT PRIMARY KEY, applied_at TIMESTAMP DEFAULT NOW());" | $PSQL

# run pending migrations
for migration in migrations/*.sql; do
    filename=$(basename "$migration" .sql)
    if ! echo "SELECT 1 FROM schema_migrations WHERE version='$filename'" | $PSQL -tA | grep -q 1; then
        echo "running $migration"
        cat "$migration" | $PSQL
        echo "INSERT INTO schema_migrations (version) VALUES ('$filename');" | $PSQL
    fi
done

dune exec nautilus