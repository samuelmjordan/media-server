open Lwt.Syntax

let get_directory req =
  let directory = Dream.query req "path" in
    match directory with
      | None -> Dream.json ~status:`Bad_Request "missing path param"
      | Some path -> 
        let* files = File_Service.read_directory path in
        let json = `List (List.map File.file_to_json files) in
        Dream.json (Yojson.Safe.to_string json)

let scan_directory req =
  let directory = Dream.query req "path" in
    match directory with
      | None -> Dream.json ~status:`Bad_Request "missing path param"
      | Some path -> 
        let* files = File_Service.scan_directory path in
          match files with
            | Error e -> Dream.respond ~status:`Internal_Server_Error e
            | Ok files -> 
              let json = `List (List.map File.file_to_json files) in
              Dream.json (Yojson.Safe.to_string json)