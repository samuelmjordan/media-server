#!/bin/bash
set -e

# Load environment variables from .env file
echo -e "\033[36mLoading environment variables from .env file...\033[0m"
if [ -f ".env" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        # Strip carriage returns
        line=$(echo "$line" | tr -d '\r')

        # Skip comments and empty lines
        if [[ $line =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
            continue
        fi

        # Only process lines that contain =
        if [[ $line == *"="* ]]; then
            name="${line%%=*}"
            value="${line#*=}"

            # Trim whitespace from name
            name=$(echo "$name" | xargs)

            # Remove surrounding quotes
            if [[ $value =~ ^\".*\"$ ]]; then
                value="${value:1:-1}"
            elif [[ $value =~ ^\'.*\'$ ]]; then
                value="${value:1:-1}"
            fi

            # Only export if name is valid
            if [[ $name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                export "$name"="$value"
                echo -e "\033[90mLoaded: $name\033[0m"
            fi
        fi
    done < .env
else
    echo -e "\033[33mWarning: .env file not found\033[0m"
fi

dune clean
dune build
docker compose up -d
sleep 2

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