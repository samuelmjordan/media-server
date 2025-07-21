let cleanup_between_tests () =
  let cmd = "docker exec test-postgres-test-1 psql -U default -d testdb -c \"
    DO \\$\\$ 
    DECLARE 
        r RECORD;
    BEGIN
        FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename != 'schema_migrations') LOOP
            EXECUTE 'TRUNCATE TABLE ' || quote_ident(r.tablename) || ' CASCADE';
        END LOOP;
    END \\$\\$;
  \"" in
  match Sys.command cmd with
  | 0 -> Printf.printf "✓ tables truncated\n"
  | _ -> Printf.printf "✗ truncate failed\n"