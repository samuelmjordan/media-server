open Lwt.Syntax

let insert file =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec File_Statements.Q.insert_file (file.File.file_id, file.path, file.name, file.mime_type, file.is_directory, file.size_bytes)) in
  match result with
  | Ok _ -> Lwt.return (Ok ())
  | Error e -> Lwt.return (Error (Caqti_error.show e))

let find file_id =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find_opt File_Statements.Q.get_file file_id) in
  match result with
  | Ok (Some (file_id, path, name, mime_type, is_directory, size_bytes)) -> 
    Lwt.return (Ok (Some { File.file_id; path; name; mime_type; is_directory; size_bytes; }))
  | Ok None -> Lwt.return (Ok None)
  | Error e -> Lwt.return (Error (Caqti_error.show e))