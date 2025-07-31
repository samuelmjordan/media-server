open Nautilus

let file_size = 1000

let test_parse_range_full_range () =
  let result = Byte_Range_Service.parse_range "bytes=0-499" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 0 range.Byte_Range.start;
      Alcotest.(check int) "end_byte" 499 range.end_byte;
      Alcotest.(check int) "total" file_size range.total
    | None -> Alcotest.fail "expected valid range"

let test_parse_range_from_start () =
  let result = Byte_Range_Service.parse_range "bytes=500-" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 500 range.start;
      Alcotest.(check int) "end_byte" 999 range.end_byte;
      Alcotest.(check int) "total" file_size range.total
    | None -> Alcotest.fail "expected valid range"

let test_parse_range_suffix () =
  let result = Byte_Range_Service.parse_range "bytes=-200" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 800 range.start;
      Alcotest.(check int) "end_byte" 999 range.end_byte;
      Alcotest.(check int) "total" file_size range.total
    | None -> Alcotest.fail "expected valid range"

let test_parse_range_invalid_format () =
  let result = Byte_Range_Service.parse_range "invalid-range" file_size in
  match result with
    | None -> ()
    | Some _ -> Alcotest.fail "expected None for invalid format"

let test_parse_range_invalid_start_end () =
  let result = Byte_Range_Service.parse_range "bytes=abc-def" file_size in
  match result with
    | None -> ()
    | Some _ -> Alcotest.fail "expected None for invalid numbers"

let test_parse_range_start_greater_than_end () =
  let result = Byte_Range_Service.parse_range "bytes=500-100" file_size in
  match result with
    | None -> ()
    | Some _ -> Alcotest.fail "expected None for start > end"

let test_parse_range_out_of_bounds () =
  let result = Byte_Range_Service.parse_range "bytes=0-1500" file_size in
  match result with
    | None -> ()
    | Some _ -> Alcotest.fail "expected None for out of bounds"

let test_parse_range_negative_start () =
  let result = Byte_Range_Service.parse_range "bytes=-500-600" file_size in
  match result with
    | None -> ()
    | Some _ -> Alcotest.fail "expected None for negative start"

let test_parse_range_start_at_file_size () =
  let result = Byte_Range_Service.parse_range "bytes=1000-" file_size in
  match result with
    | None -> ()
    | Some _ -> Alcotest.fail "expected None for start at file size"

let test_parse_range_suffix_too_large () =
  let result = Byte_Range_Service.parse_range "bytes=-1500" file_size in
  match result with
    | None -> ()
    | Some _ -> Alcotest.fail "expected None for suffix too large"

let test_parse_range_zero_suffix () =
  let result = Byte_Range_Service.parse_range "bytes=-0" file_size in
  match result with
    | None -> ()
    | Some _ -> Alcotest.fail "expected None for zero suffix"

let test_parse_range_single_byte () =
  let result = Byte_Range_Service.parse_range "bytes=500-500" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 500 range.start;
      Alcotest.(check int) "end_byte" 500 range.end_byte;
      Alcotest.(check int) "total" file_size range.total
    | None -> Alcotest.fail "expected valid single byte range"

let test_parse_range_entire_file () =
  let result = Byte_Range_Service.parse_range "bytes=0-999" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 0 range.start;
      Alcotest.(check int) "end_byte" 999 range.end_byte;
      Alcotest.(check int) "total" file_size range.total
    | None -> Alcotest.fail "expected valid full file range"

let test_parse_range_last_byte () =
  let result = Byte_Range_Service.parse_range "bytes=-1" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 999 range.start;
      Alcotest.(check int) "end_byte" 999 range.end_byte;
      Alcotest.(check int) "total" file_size range.total
    | None -> Alcotest.fail "expected valid last byte range"

let cases =
  "byte range service", [
    Alcotest.test_case "parse range full range" `Quick test_parse_range_full_range;
    Alcotest.test_case "parse range from start" `Quick test_parse_range_from_start;
    Alcotest.test_case "parse range suffix" `Quick test_parse_range_suffix;
    Alcotest.test_case "parse range invalid format" `Quick test_parse_range_invalid_format;
    Alcotest.test_case "parse range invalid start end" `Quick test_parse_range_invalid_start_end;
    Alcotest.test_case "parse range start greater than end" `Quick test_parse_range_start_greater_than_end;
    Alcotest.test_case "parse range out of bounds" `Quick test_parse_range_out_of_bounds;
    Alcotest.test_case "parse range negative start" `Quick test_parse_range_negative_start;
    Alcotest.test_case "parse range start at file size" `Quick test_parse_range_start_at_file_size;
    Alcotest.test_case "parse range suffix too large" `Quick test_parse_range_suffix_too_large;
    Alcotest.test_case "parse range zero suffix" `Quick test_parse_range_zero_suffix;
    Alcotest.test_case "parse range single byte" `Quick test_parse_range_single_byte;
    Alcotest.test_case "parse range entire file" `Quick test_parse_range_entire_file;
    Alcotest.test_case "parse range last byte" `Quick test_parse_range_last_byte;
  ]