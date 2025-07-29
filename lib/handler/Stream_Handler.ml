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

let media_playlist request =
  let file_id_str = Dream.param request "file_id" in
  match File.File_Uuid.from_string file_id_str with
  | Error _ -> Dream.respond ~status:`Bad_Request "invalid file id format"
  | Ok file_id ->
    let quality_str = Dream.param request "quality" in
    match Quality.quality_of_string quality_str with
    | Error _ -> Dream.respond ~status:`Bad_Request "invalid quality format"
    | Ok quality ->
      let* result = Hls_Service.media_playlist file_id quality in
      match result with
      | Error e -> Dream.respond ~status:`Internal_Server_Error e
      | Ok None -> Dream.respond ~status:`Not_Found "file not found"
      | Ok Some playlist -> Dream.respond ~headers:["Content-Type", "application/vnd.apple.mpegurl"] playlist

let serve_segment request =
  let file_id_str = Dream.param request "file_id" in
  match File.File_Uuid.from_string file_id_str with
  | Error _ -> Dream.respond ~status:`Bad_Request "invalid file id format"
  | Ok file_id ->
    let quality_str = Dream.param request "quality" in
    match Quality.quality_of_string quality_str with
    | Error _ -> Dream.respond ~status:`Bad_Request "invalid quality format"
    | Ok quality ->
      let segment_num = int_of_string (Dream.param request "num") in
      let* segment_path = Hls_Service.get_segment_path file_id quality segment_num in
      match segment_path with
      | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error" 
      | Ok None -> Dream.respond ~status:`Not_Found "segment not found" 
      | Ok Some path ->
        Dream.stream ~headers:["Content-Type", "video/mp2t"; "Cache-Control", "public, max-age=86400"]
          (Stream_Service.stream_whole_file path)