open Lwt.Syntax

type range = Single of int * int option | Multi of (int * int option) list

let read_file file_path =
  let open Lwt.Syntax in
  let* ic = Lwt_io.open_file ~mode:Input file_path in
  let* content = Lwt_io.read ic in
  let* () = Lwt_io.close ic in
  Lwt.return content
let parse_range_header header file_size =
  let parse_single_range range_str =
    match String.split_on_char '-' (String.trim range_str) with
    | [start_str; ""] -> 
      (match int_of_string_opt start_str with
       | Some start when start >= 0 && start < file_size -> Some (start, None)
       | _ -> None)
    | [""; suffix_str] -> 
      (match int_of_string_opt suffix_str with
       | Some suffix when suffix > 0 -> 
         let start = max 0 (file_size - suffix) in
         Some (start, None)
       | _ -> None)
    | [start_str; end_str] -> 
      (match int_of_string_opt start_str, int_of_string_opt end_str with
       | Some start, Some end_pos when start >= 0 && end_pos >= start && start < file_size ->
         Some (start, Some (min end_pos (file_size - 1)))
       | _ -> None)
    | _ -> None
  in
  
  match String.split_on_char '=' header with
  | ["bytes"; ranges_str] ->
    let range_strs = String.split_on_char ',' ranges_str in
    let parsed_ranges = List.filter_map parse_single_range range_strs in
    (match parsed_ranges with
     | [] -> None (* all ranges were invalid *)
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