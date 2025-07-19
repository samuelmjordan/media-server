open Lwt.Syntax
open User

let user_to_json user =
  `Assoc [
    ("user_id", `String (User.User_Uuid.to_string user.user_id));
    ("name", `String user.name);
    ("email", `String user.email);
  ]

let json_to_user json =
  let open Yojson.Safe.Util in
  let user_id_str = json |> member "user_id" |> to_string in
  let name = json |> member "name" |> to_string in
  let email = json |> member "email" |> to_string in
  match User.User_Uuid.from_string user_id_str with
  | Ok user_id -> Ok { user_id; name; email }
  | Error msg -> Error ("invalid user_id: " ^ msg)

let json_to_user_create json =
  let open Yojson.Safe.Util in
  let name = json |> member "name" |> to_string in
  let email = json |> member "email" |> to_string in
  (name, email)

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
      let json = `List (List.map user_to_json users) in
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
      Dream.json (Yojson.Safe.to_string (user_to_json user))
    | Ok None -> Dream.respond ~status:`Not_Found "user not found"
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "db error"

let create_user req =
  let* body = Dream.body req in
  match Yojson.Safe.from_string body with
  | json ->
    (match json_to_user_create json with
      | (name, email) ->
        let user_id = User.User_Uuid.make () in
        let* result = 
          Caqti_lwt_unix.with_connection (Uri.of_string Db.db_url) (fun db ->
            Db.create_user ~user_id ~name ~email db
          ) in
        (match result with
          | Ok () -> 
            let user = { user_id; name; email } in
            Dream.json (Yojson.Safe.to_string (user_to_json user))
          | Error _ -> Dream.respond ~status:`Internal_Server_Error "db error")
      | exception _ -> Dream.respond ~status:`Bad_Request "missing name or email")
  | exception _ -> Dream.respond ~status:`Bad_Request "invalid json"