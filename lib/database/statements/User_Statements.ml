module Q = struct
  open Caqti_request.Infix
  
  let create_user =
    Caqti_type.(t3 User.User_Uuid.caqti_type string string) ->. Caqti_type.unit
    @@
    "INSERT INTO user_ (user_id, name, email) VALUES (?, ?, ?)"

  let get_all_users =
    Caqti_type.unit ->* Caqti_type.(t3 User.User_Uuid.caqti_type string string)
    @@
    "SELECT user_id, name, email FROM user_ ORDER BY created_at"

  let get_user_by_id =
    User.User_Uuid.caqti_type ->? Caqti_type.(t3 User.User_Uuid.caqti_type string string)
    @@
    "SELECT user_id, name, email FROM user_ WHERE user_id = ?"
end