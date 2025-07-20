open Lwt.Syntax
open User

let get_all_users _req =
  let* result = 
    Caqti_lwt_unix.with_connection (Uri.of_string Db.db_url) (fun db ->
      Db.get_all_users db
    ) in
  match result with
  | Ok rows ->
    let rec convert_users acc = function
      | [] -> Ok (List.rev acc)
      | (user_id, name, email) :: rest ->
        match User.User_Uuid.from_string user_id with
        | Ok user_id -> convert_users ({ user_id; name; email } :: acc) rest
        | Error _ -> Error "invalid user_id in db"
    in
    (match convert_users [] rows with
    | Ok users ->
      let json = `List (List.map User.user_to_json users) in
      Dream.json (Yojson.Safe.to_string json)
    | Error _ ->
      Dream.respond ~status:`Internal_Server_Error "invalid user data"
    )
  | Error _ ->
    Dream.respond ~status:`Internal_Server_Error "db error"
  
let get_user_by_id req =
  let user_id_str = Dream.param req "user_id" in
  match User.User_Uuid.from_string user_id_str with
  | Error _ -> Dream.respond ~status:`Bad_Request "invalid user id format"
  | Ok user_id ->
    let* result = 
      Caqti_lwt_unix.with_connection (Uri.of_string Db.db_url) (fun db ->
        Db.get_user_by_id ~user_id db
      ) in
    match result with
    | Ok (Some (user_id, name, email)) ->
      let user = { user_id; name; email } in
      Dream.json (Yojson.Safe.to_string (User.user_to_json user))
    | Ok None -> Dream.respond ~status:`Not_Found "user not found"
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "db error"

let create_user req =
  let* body = Dream.body req in
  match Yojson.Safe.from_string body with
  | json ->
    (match User.json_to_user_create json with
      | (name, email) ->
        let user_id = User.User_Uuid.make () in
        let* result = 
          Caqti_lwt_unix.with_connection (Uri.of_string Db.db_url) (fun db ->
            Db.create_user ~user_id ~name ~email db
          ) in
        (match result with
          | Ok () -> 
            let user = { user_id; name; email } in
            Dream.json (Yojson.Safe.to_string (User.user_to_json user))
          | Error _ -> Dream.respond ~status:`Internal_Server_Error "db error")
      | exception _ -> Dream.respond ~status:`Bad_Request "missing name or email")
  | exception _ -> Dream.respond ~status:`Bad_Request "invalid json"