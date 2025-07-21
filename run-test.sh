#!/bin/bash
dune build
docker compose -f ./test/compose.yml up -d
sleep 2

# use the postgres container to run psql
CONTAINER_ID=$(docker compose -f ./test/compose.yml ps -q postgres-test)
PSQL="docker exec -i $CONTAINER_ID psql -U default -d testdb"

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

echo -e "\033[32mstarting dune clean...\033[0m"
dune clean
echo -e "\033[32mclean done.\033[0m"

echo -e "\033[32mstarting dune test...\033[0m"
dune test
echo -e "\033[32mtest done.\033[0m"