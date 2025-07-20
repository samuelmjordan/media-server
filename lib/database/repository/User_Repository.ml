open Lwt.Syntax

let convert_row_to_user (user_id_str, name, email) =
  match User.User_Uuid.from_string user_id_str with
    | Ok user_id -> Ok { User.user_id; name; email }
    | Error _ -> Error "invalid user_id in db"

let create ~user_id ~name ~email =
  Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec User_Statements.Q.create_user (user_id, name, email))

let find_by_id ~user_id =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find_opt User_Statements.Q.get_user_by_id user_id) in
  match result with
  | Ok (Some row) -> 
    (match convert_row_to_user row with
    | Ok user -> Lwt.return (Ok (Some user))
    | Error e -> Lwt.return (Error e))
  | Ok None -> Lwt.return (Ok None)
  | Error e -> Lwt.return (Error (Caqti_error.show e))

let find_all () =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.collect_list User_Statements.Q.get_all_users ()) in
 match result with
  | Ok rows ->
    let rec convert_users acc = function
      | [] -> Ok (List.rev acc)
      | row :: rest ->
        (match convert_row_to_user row with
        | Ok user -> convert_users (user :: acc) rest
        | Error e -> Error e)
    in
    Lwt.return (convert_users [] rows)
  | Error _ -> Lwt.return (Error "db error")