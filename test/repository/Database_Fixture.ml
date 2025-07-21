let test_uri = Uri.of_string "postgresql://default:password@localhost:5433/testdb"

let setup_once () =
  let cmd = "docker exec nautilus-postgres-test-1 sh -c 'find /migrations -name \"*.sql\" | sort | xargs cat | psql -U default -d testdb'" in
  match Sys.command cmd with
  | 0 -> ()
  | _ -> failwith "migration failed"

let cleanup_between_tests () =
  let cmd = "psql -h localhost -p 5433 -U default -d testdb -c 'TRUNCATE TABLE file_ CASCADE'" in
  ignore (Sys.command cmd)