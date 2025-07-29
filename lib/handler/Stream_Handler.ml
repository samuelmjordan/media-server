open Lwt.Syntax

let master_playlist request =
  let file_id_str = Dream.param request "file_id" in
  match File.File_Uuid.from_string file_id_str with
    | Error _ -> Dream.respond ~status:`Bad_Request "invalid file id format"
    | Ok file_id ->
      let* result = Hls_Service.master_playlist file_id in
      match result with
      | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
      | Ok None -> Dream.respond ~status:`Not_Found "file not found"
      | Ok Some playlist -> Dream.respond ~headers:["Content-Type", "application/vnd.apple.mpegurl"] playlist