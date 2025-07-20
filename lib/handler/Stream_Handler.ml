open Lwt.Syntax

let make_headers ~file_name ~mime_type ?(extra_headers = []) () =
  let filename_header = ("Content-Disposition", Printf.sprintf "inline; filename=\"%s\"" file_name) in
  let content_type = ("Content-Type", mime_type) in
  content_type :: filename_header :: extra_headers

let serve_full_file file =
  let full_path = Filename.concat file.File.path file.name in
  let* content = Stream_Service.read_file full_path in
  let headers = make_headers ~file_name:file.name ~mime_type:file.mime_type () in
  Dream.respond ~headers content

let serve_range_request file range_header =
  let* () = Lwt.return () in
  match Stream_Service.parse_range_header range_header file.File.size_bytes with
  | None -> Dream.respond ~status:`Bad_Request "invalid range header"
  | Some range ->
    match Stream_Service.make_range_headers ~file_size:file.size_bytes range with
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
    | Ok range_headers ->
      let* content_result = Stream_Service.make_range_response 
        ~file_path:file.path ~file_name:file.name ~range ~file_size:file.size_bytes in
      match content_result with
      | Error err -> Dream.respond ~status:`Internal_Server_Error err
      | Ok content -> 
        let headers = make_headers ~file_name:file.name ~mime_type:file.mime_type ~extra_headers:range_headers () in
        Dream.respond ~status:`Partial_Content ~headers content

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
      | None -> serve_full_file file
      | Some range_header -> serve_range_request file range_header