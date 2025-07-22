open Lwt.Syntax

let make_headers ~mime_type ?(extra_headers = []) () =
  let accept_ranges = ("Accept-Ranges", "bytes") in
  let content_type = ("Content-Type", mime_type) in
  content_type :: accept_ranges :: extra_headers

let make_range_headers ~range_result =
  let { Stream_Service.start_byte; end_byte; total_size; _ } = range_result in
  let content_length = end_byte - start_byte + 1 in
  [
    ("Content-Range", Printf.sprintf "bytes %d-%d/%d" start_byte end_byte total_size);
    ("Content-Length", string_of_int content_length);
  ]

let serve_full_file file =
  let full_path = Filename.concat file.File.path file.name in
  let* content = Stream_Service.read_file full_path in
  let headers = make_headers ~mime_type:file.mime_type () in
  Dream.respond ~headers content

let serve_range_request file range_header =
  let* () = Lwt.return () in
  match Stream_Service.parse_range_header range_header file.File.size_bytes with
    | None -> Dream.respond ~status:`Bad_Request "invalid range header"
    | Some range ->
  let* content_result = Stream_Service.make_range_response 
    ~file_path:file.path ~file_name:file.name ~range ~file_size:file.size_bytes in
  match content_result with
    | Error err -> Dream.respond ~status:`Internal_Server_Error err
    | Ok range_result -> 
  let range_headers = make_range_headers ~range_result in
  let headers = make_headers ~mime_type:file.mime_type ~extra_headers:range_headers () in
  Dream.respond ~status:`Partial_Content ~headers range_result.content

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