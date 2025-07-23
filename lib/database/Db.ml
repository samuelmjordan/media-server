let with_connection f = 
  Caqti_lwt_unix.with_connection (Config.get_db_uri ()) f
