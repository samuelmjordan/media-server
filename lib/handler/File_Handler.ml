open Lwt.Syntax

let get_directory req =
  let directory = Dream.query req "path" in
   match directory with
    | Some path -> 
      let* files = File_Service.read_dir path in
      let json = `List (List.map File.file_to_json files) in
      Dream.json (Yojson.Safe.to_string json)
    | None -> 
      Dream.json ~status:`Bad_Request {|{"error": "missing path param"}|}