open Lwt.Syntax

let insert file =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec File_Statements.Q.insert_file (file.File.file_id, file.path, file.name, file.is_directory, file.is_video, file.size_bytes)) in
  match result with
  | Ok _ -> Lwt.return (Ok ())
  | Error e -> Lwt.return (Error (Caqti_error.show e))

let find file_id =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find_opt File_Statements.Q.get_file file_id) in
  match result with
  | Ok (Some (file_id, path, name, is_directory, is_video, size_bytes)) -> 
    Lwt.return (Ok (Some { File.file_id; path; name; is_directory; is_video; size_bytes; }))
  | Ok None -> Lwt.return (Ok None)
  | Error e -> Lwt.return (Error (Caqti_error.show e))