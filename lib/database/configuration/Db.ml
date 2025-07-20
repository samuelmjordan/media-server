let db_url = "postgresql://default:password@localhost:3306/mydatabase"

let with_connection f = 
  Caqti_lwt_unix.with_connection (Uri.of_string db_url) f