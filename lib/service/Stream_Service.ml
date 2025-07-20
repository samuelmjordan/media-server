open Lwt.Syntax

type range = Single of int * int option | Multi of (int * int option) list

let read_file file_path =
  let open Lwt.Syntax in
  let* ic = Lwt_io.open_file ~mode:Input file_path in
  let* content = Lwt_io.read ic in
  let* () = Lwt_io.close ic in
  Lwt.return content

let parse_range_header header file_size =
  match String.split_on_char '=' header with
  | ["bytes"; ranges] ->
    let parsed_ranges = String.split_on_char ',' ranges
    |> List.map (fun range ->
      match String.split_on_char '-' (String.trim range) with
      | [start; ""] -> (int_of_string start, None) (* 1000- *)
      | [""; suffix] -> (max 0 (file_size - int_of_string suffix), None) (* -500 = last 500 bytes *)
      | [start; end_] -> (int_of_string start, Some (int_of_string end_)) (* 1000-2000 *)
      | _ -> failwith "bad range") in
    (match parsed_ranges with
     | [(start, end_opt)] -> Some (Single (start, end_opt))
     | multiple -> Some (Multi multiple))
  | _ -> None

let make_range_headers ~file_size = function
  | Single (start, end_opt) ->
    let end_byte = match end_opt with 
      | Some e -> min e (file_size - 1)
      | None -> file_size - 1 in
    let content_length = end_byte - start + 1 in
    Ok [
      ("Content-Range", Printf.sprintf "bytes %d-%d/%d" start end_byte file_size);
      ("Accept-Ranges", "bytes");
      ("Content-Length", string_of_int content_length);
    ]
  | Multi _ -> Error  "multipart not implemented"

let read_file_range ~file_path ~start ~end_byte =
  let* ic = Lwt_io.open_file ~mode:Input file_path in
  let content_length = end_byte - start + 1 in
  let* () = Lwt_io.set_position ic (Int64.of_int start) in
  let* content = Lwt_io.read ~count:content_length ic in
  let* () = Lwt_io.close ic in
  Lwt.return content

let make_range_response ~file_path ~file_name ~range ~file_size =
  match range with
  | Single (start, end_opt) ->
    let end_byte = match end_opt with 
      | Some e -> min e (file_size - 1) 
      | None -> file_size - 1 in
    let* content = read_file_range 
      ~file_path:(Filename.concat file_path file_name) 
      ~start ~end_byte in
    Lwt.return (Ok content)
  | Multi _ -> Lwt.return (Error  "multipart not implemented")