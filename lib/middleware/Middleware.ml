open Lwt.Syntax

let log_request_headers next_handler request =
  let headers = Dream.all_headers request in
  List.iter (fun (name, value) -> 
    Dream.log "Header: %s: %s" name value) headers;
  next_handler request

let log_response_headers next_handler request =
  let* response = next_handler request in
  let headers = Dream.all_headers response in
  List.iter (fun (name, value) -> 
    Dream.log "Response Header: %s: %s" name value) headers;
  Lwt.return response