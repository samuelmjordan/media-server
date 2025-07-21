module type DB_CONFIG = sig
  val connection_uri : Uri.t
end

let default_config = 
  let module Config = struct
    let connection_uri = Uri.of_string "postgresql://default:password@localhost:3306/mydatabase"
  end in
  (module Config : DB_CONFIG)

let with_connection_uri uri f = 
  Caqti_lwt_unix.with_connection uri f

let with_connection f = 
  let (module Config : DB_CONFIG) = default_config in
  with_connection_uri Config.connection_uri f