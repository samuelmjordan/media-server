open Lwt.Syntax
open User

let get_all_users _req =
  let* result = User_Repository.find_all () in
  match result with
  | Error _ -> Dream.respond ~status:`Internal_Server_Error "failed to fetch users"
  | Ok users ->
    let json = `List (List.map User.user_to_json users) in
    Dream.json (Yojson.Safe.to_string json)
  
let get_user_by_id req =
 let user_id_str = Dream.param req "user_id" in
 match User.User_Uuid.from_string user_id_str with
 | Error _ -> Dream.respond ~status:`Bad_Request "invalid user id format"
 | Ok user_id ->
   let* result = User_Repository.find_by_id ~user_id () in
   match result with
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
    | Ok None -> Dream.respond ~status:`Not_Found "user not found"
    | Ok (Some user) -> Dream.json (Yojson.Safe.to_string (User.user_to_json user))

let create_user req =
  let* body = Dream.body req in
  match Yojson.Safe.from_string body with
  | exception _ -> Dream.respond ~status:`Bad_Request "invalid json"
  | json ->
    (match User.json_to_user_create json with
      | exception _ -> Dream.respond ~status:`Bad_Request "missing name or email"
      | (name, email) ->
        let user_id = User.User_Uuid.make () in
        let* result = User_Repository.create ~user_id ~name ~email () in
        (match result with
          | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
          | Ok () -> 
            let user = { user_id; name; email } in
            Dream.json (Yojson.Safe.to_string (User.user_to_json user))))