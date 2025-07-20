open Lwt.Syntax

let stream_media request =
  let file_id_str = Dream.param request "file_id" in
  match File.File_Uuid.from_string file_id_str with
  | Error _ -> Dream.respond ~status:`Bad_Request "invalid file id format"
  | Ok file_id ->
    let* result = File_Service.get_file file_id in
    match result with
      | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
      | Ok None -> Dream.respond ~status:`Not_Found "file not found"
      | Ok (Some file) -> 
        match Dream.header request "Range" with
          | None ->
            let full_path = Filename.concat file.path file.name in
            let* content = Stream_Service.read_file full_path in
            Dream.respond ~headers:[("Content-Type", file.mime_type)] content
          | Some range_header ->
            let ranges_result = Stream_Service.parse_range_header range_header file.size_bytes in
            match ranges_result with
            | None -> Dream.respond ~status:`Bad_Request "invalid range header"
            | Some range ->
              let headers = Stream_Service.make_range_headers ~file_size:file.size_bytes range in
                match headers with 
                  | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
                  | Ok headers ->
                    let* content_result = Stream_Service.make_range_response ~file_path:file.path ~file_name:file.name ~range ~file_size:file.size_bytes in
                    match content_result with
                    | Error err -> Dream.respond ~status:`Internal_Server_Error err
                    | Ok content -> Dream.respond ~status:`Partial_Content ~headers content