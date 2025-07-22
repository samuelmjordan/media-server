open Lwt.Syntax

type range = Single of int * int option | Multi of (int * int option) list

type range_result = {
  start_byte: int;
  end_byte: int;
  total_size: int;
}

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

let create_stream_function ~file_path ~start ~end_byte =
  let chunk_size = 65536 in (* 64KB chunks *)
  let ic = ref None in
  let current_pos = ref start in
  let remaining = ref (end_byte - start + 1) in
  
  fun () ->
    if !remaining <= 0 then (
      (* close file if still open *)
      let* () = match !ic with
        | Some channel -> let* () = Lwt_io.close channel in ic := None; Lwt.return ()
        | None -> Lwt.return ()
      in
      Lwt.return None
    ) else
      (* open file on first call *)
      let* channel = match !ic with
        | Some ch -> Lwt.return ch
        | None ->
          let* ch = Lwt_io.open_file ~mode:Input file_path in
          let* () = Lwt_io.set_position ch (Int64.of_int start) in
          ic := Some ch;
          Lwt.return ch
      in
      
      let to_read = min chunk_size !remaining in
      let* chunk = Lwt_io.read ~count:to_read channel in
      let actual_read = String.length chunk in
      
      if actual_read = 0 then (
        (* EOF reached, close file *)
        let* () = Lwt_io.close channel in
        ic := None;
        Lwt.return None
      ) else (
        current_pos := !current_pos + actual_read;
        remaining := !remaining - actual_read;
        Lwt.return (Some chunk)
      )

let make_range_response ~file_path ~file_name ~range ~file_size =
  match range with
  | Single (start, end_opt) ->
    let end_byte = match end_opt with 
      | Some e -> min e (file_size - 1) 
      | None -> file_size - 1 in
    let full_path = Filename.concat file_path file_name in
    let stream_func = create_stream_function ~file_path:full_path ~start ~end_byte in
    Lwt.return (Ok ({ start_byte = start; end_byte; total_size = file_size }, stream_func))
  | Multi _ -> Lwt.return (Error "multipart not implemented")