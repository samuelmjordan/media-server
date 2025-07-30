open Lwt.Syntax
open Handler

let get_directory req =
  with_query_param req "path" (fun path ->
  with_query_param req "mime" (fun mime_filter ->
  let* result = File_Service.get_directory_files ~path ~mime_filter () in
  match result with
  | Error e -> Dream.respond ~status:`Internal_Server_Error e
  | Ok files ->
    let json = `List (List.map File.file_to_json files) in
    Dream.json (Yojson.Safe.to_string json)))

let delete_directory req =
  with_query_param req "path" (fun path ->
  let* result = File_Service.delete_directory path in
  match result with
  | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
  | Ok 0 -> Dream.respond ~status:`Not_Found ({|{"deleted": 0}|})
  | Ok count -> Dream.json ~status:`OK (Printf.sprintf {|{"deleted": %d}|} count))
    
let scan_directory req =
  with_query_param req "path" (fun path ->
    let* files = File_Service.scan_directory path in
    match files with
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
    | Ok files -> 
      let json = `List (List.map File.file_to_json files) in
      Dream.json (Yojson.Safe.to_string json))

let get_file req =
  let file_id_str = Dream.param req "file_id" in
  match File.File_Uuid.from_string file_id_str with
  | Error _ -> Dream.respond ~status:`Bad_Request "invalid file id format"
  | Ok file_id ->
    let* result = File_Service.get_file file_id in
    match result with
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
    | Ok None -> Dream.respond ~status:`Not_Found "file not found"
    | Ok (Some file) -> Dream.json (Yojson.Safe.to_string (File.file_to_json file))