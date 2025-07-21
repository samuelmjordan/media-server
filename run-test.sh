dune build
docker compose -f test-compose.yml up -d
sleep 2
dune test
docker compose -f test-compose.yml down