let db_url = "postgresql://default:password@localhost:3306/mydatabase"

module Q = struct
  open Caqti_request.Infix
  
  let create_user =
    Caqti_type.(t3 string string string) ->. Caqti_type.unit
    @@
    "INSERT INTO user_ (user_id, name, email) VALUES (?, ?, ?)"

  let get_all_users =
    Caqti_type.unit ->* Caqti_type.(t3 string string string)
    @@
    "SELECT user_id, name, email FROM user_ ORDER BY created_at"

  let get_user_by_id =
    Caqti_type.string ->? Caqti_type.(t3 string string string)
    @@
    "SELECT user_id, name, email FROM user_ WHERE user_id = ?"
end

let create_user ~user_id ~name ~email (module Db : Caqti_lwt.CONNECTION) =
  Db.exec Q.create_user (user_id, name, email)

let get_all_users (module Db : Caqti_lwt.CONNECTION) =
  Db.collect_list Q.get_all_users ()

let get_user_by_id ~user_id (module Db : Caqti_lwt.CONNECTION) =
  Db.find_opt Q.get_user_by_id user_id