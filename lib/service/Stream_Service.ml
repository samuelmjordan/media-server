open Lwt.Syntax

type range = { start: int; end_byte: int; total: int }

let parse_range range_header file_size =
  match String.split_on_char '=' range_header with
  | ["bytes"; range_str] ->
    (match String.split_on_char '-' (String.trim range_str) with
    | [start_str; end_str] when start_str <> "" && end_str <> "" ->
      (match int_of_string_opt start_str, int_of_string_opt end_str with
      | Some start, Some end_byte when start >= 0 && end_byte < file_size && start <= end_byte ->
        Some { start; end_byte; total = file_size }
      | _ -> None)
    | [start_str; ""] when start_str <> "" ->
      (match int_of_string_opt start_str with
      | Some start when start >= 0 && start < file_size ->
        Some { start; end_byte = file_size - 1; total = file_size }
      | _ -> None)
    | [""; suffix_str] when suffix_str <> "" ->
      (match int_of_string_opt suffix_str with
      | Some suffix when suffix > 0 && suffix <= file_size ->
        let start = file_size - suffix in
        Some { start; end_byte = file_size - 1; total = file_size }
      | _ -> None)
    | _ -> None)
  | _ -> None

let stream_file_range file_path range stream =
  let chunk_size = 64 * 1024 in
  let remaining = ref (range.end_byte - range.start + 1) in
  
  let* ic = Lwt_io.open_file ~mode:Input file_path in
  let* () = Lwt_io.set_position ic (Int64.of_int range.start) in
  
  let rec write_chunks () =
    if !remaining <= 0 then (
      let* () = Lwt_io.close ic in
      Lwt.return ()
    ) else (
      let to_read = min chunk_size !remaining in
      Lwt.catch 
        (fun () ->
          let* chunk = Lwt_io.read ~count:to_read ic in
          let len = String.length chunk in
          remaining := !remaining - len;
          if len = 0 then (
            let* () = Lwt_io.close ic in
            Lwt.return ()
          ) else (
            let* () = Dream.write stream chunk in
            write_chunks ()))
        (fun _exn ->
          let* () = Lwt_io.close ic in
          Lwt.return ())) in
  
  write_chunks ()

let stream_whole_file file_path stream =
  let chunk_size = 64 * 1024 in
  let* ic = Lwt_io.open_file ~mode:Input file_path in
  
  let rec write_chunks () =
    Lwt.catch
      (fun () ->
        let* chunk = Lwt_io.read ~count:chunk_size ic in
        if String.length chunk = 0 then (
          let* () = Lwt_io.close ic in
          Lwt.return ()
        ) else (
          let* () = Dream.write stream chunk in
          write_chunks ()))
      (fun _exn ->
        let* () = Lwt_io.close ic in
        Lwt.return ()) in
  
  write_chunks ()