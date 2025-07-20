open Lwt.Syntax

let get_directory req =
  let directory = Dream.param req "directory" in
  let* files = File_Service.read_dir directory in
  let json = `List (List.map File.file_to_json files) in
  Dream.json (Yojson.Safe.to_string json)