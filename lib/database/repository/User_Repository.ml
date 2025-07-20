open Lwt.Syntax

let create ~user_id ~name ~email =
  Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec User_Statements.Q.create_user (user_id, name, email))

let find_by_id ~user_id =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find_opt User_Statements.Q.get_user_by_id user_id) in
  match result with
  | Ok (Some (user_id, name, email)) -> 
    Lwt.return (Ok (Some { User.user_id; name; email }))
  | Ok None -> Lwt.return (Ok None)
  | Error e -> Lwt.return (Error (Caqti_error.show e))

let find_all () =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.collect_list User_Statements.Q.get_all_users ()) in
 match result with
  | Ok rows ->
    let users = List.map (fun (user_id, name, email) -> 
      { User.user_id; name; email }) rows in
    Lwt.return (Ok users)
  | Error e -> Lwt.return (Error e)