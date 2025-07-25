open Lwt.Syntax
open Stream_Service

let stream_media request =
  let file_id = Dream.param request "file_id" in

  let* file_result = File_Repository.find file_id in
  match file_result with
  | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
  | Ok None -> Dream.respond ~status:`Not_Found "file not found"
  | Ok Some file ->
    let file_path = Filename.concat file.path file.name in
    
    Lwt.catch 
      (fun () ->
        match Dream.header request "Range" with
        | None -> 
          Dream.stream ~status:`OK 
            ~headers:[
              "Content-Type", file.mime_type;
              "Content-Length", string_of_int file.size_bytes;
              "Accept-Ranges", "bytes";
              "Cache-Control", "public, max-age=3600";
            ]
            (stream_whole_file file_path)
        | Some range_header ->
          match parse_range range_header file.size_bytes with
          | None -> 
            Dream.respond ~status:`Range_Not_Satisfiable 
              ~headers:["Content-Range", Printf.sprintf "bytes */%d" file.size_bytes]
              ""
          | Some range ->
            let content_length = range.end_byte - range.start + 1 in
            Dream.stream ~status:`Partial_Content
              ~headers:[
                "Content-Type", file.mime_type;
                "Content-Range", Printf.sprintf "bytes %d-%d/%d" range.start range.end_byte range.total;
                "Content-Length", string_of_int content_length;
                "Accept-Ranges", "bytes";
                "Cache-Control", "public, max-age=3600";
              ]
              (stream_file_range file_path range))
      (fun exn ->
        Dream.log "file error: %s" (Printexc.to_string exn);
        Dream.respond ~status:`Not_Found "file not accessible")