let connection_pool = lazy (
  let pool_config = Caqti_pool_config.create ~max_size:10 () in
  Caqti_lwt_unix.connect_pool ~pool_config (Config.get_db_uri ())
)

let with_pool f =
  let pool_result = Lazy.force connection_pool in
  match pool_result with
  | Ok pool -> Caqti_lwt_unix.Pool.use f pool
  | Error err -> Lwt.return (Error err)

let with_connection = with_pool
