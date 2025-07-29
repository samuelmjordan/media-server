let parse_range range_header file_size =
  match String.split_on_char '=' range_header with
  | ["bytes"; range_str] ->
    (match String.split_on_char '-' (String.trim range_str) with
    | [start_str; end_str] when start_str <> "" && end_str <> "" ->
      (match int_of_string_opt start_str, int_of_string_opt end_str with
      | Some start, Some end_byte when start >= 0 && end_byte < file_size && start <= end_byte ->
        Some Byte_Range.{ start; end_byte; total = file_size }
      | _ -> None)
    | [start_str; ""] when start_str <> "" ->
      (match int_of_string_opt start_str with
      | Some start when start >= 0 && start < file_size ->
        Some Byte_Range.{ start; end_byte = file_size - 1; total = file_size }
      | _ -> None)
    | [""; suffix_str] when suffix_str <> "" ->
      (match int_of_string_opt suffix_str with
      | Some suffix when suffix > 0 && suffix <= file_size ->
        let start = file_size - suffix in
        Some Byte_Range.{ start; end_byte = file_size - 1; total = file_size }
      | _ -> None)
    | _ -> None)
  | _ -> None