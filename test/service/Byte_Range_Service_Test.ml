open Case_Fixture
open Nautilus

let file_size = 1000

let test_parse_range_full_range _switch () =
  let result = Byte_Range_Service.parse_range "bytes=0-499" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 0 range.Byte_Range.start;
      Alcotest.(check int) "end_byte" 499 range.end_byte;
      Alcotest.(check int) "total" file_size range.total;
      Lwt.return ()
    | None -> Alcotest.fail "expected valid range"

let test_parse_range_from_start _switch () =
  let result = Byte_Range_Service.parse_range "bytes=500-" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 500 range.start;
      Alcotest.(check int) "end_byte" 999 range.end_byte;
      Alcotest.(check int) "total" file_size range.total;
      Lwt.return ()
    | None -> Alcotest.fail "expected valid range"

let test_parse_range_suffix _switch () =
  let result = Byte_Range_Service.parse_range "bytes=-200" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 800 range.start;
      Alcotest.(check int) "end_byte" 999 range.end_byte;
      Alcotest.(check int) "total" file_size range.total;
      Lwt.return ()
    | None -> Alcotest.fail "expected valid range"

let test_parse_range_invalid_format _switch () =
  let result = Byte_Range_Service.parse_range "invalid-range" file_size in
  match result with
    | None -> Lwt.return ()
    | Some _ -> Alcotest.fail "expected None for invalid format"

let test_parse_range_invalid_start_end _switch () =
  let result = Byte_Range_Service.parse_range "bytes=abc-def" file_size in
  match result with
    | None -> Lwt.return ()
    | Some _ -> Alcotest.fail "expected None for invalid numbers"

let test_parse_range_start_greater_than_end _switch () =
  let result = Byte_Range_Service.parse_range "bytes=500-100" file_size in
  match result with
    | None -> Lwt.return ()
    | Some _ -> Alcotest.fail "expected None for start > end"

let test_parse_range_out_of_bounds _switch () =
  let result = Byte_Range_Service.parse_range "bytes=0-1500" file_size in
  match result with
    | None -> Lwt.return ()
    | Some _ -> Alcotest.fail "expected None for out of bounds"

let test_parse_range_negative_start _switch () =
  let result = Byte_Range_Service.parse_range "bytes=-500-600" file_size in
  match result with
    | None -> Lwt.return ()
    | Some _ -> Alcotest.fail "expected None for negative start"

let test_parse_range_start_at_file_size _switch () =
  let result = Byte_Range_Service.parse_range "bytes=1000-" file_size in
  match result with
    | None -> Lwt.return ()
    | Some _ -> Alcotest.fail "expected None for start at file size"

let test_parse_range_suffix_too_large _switch () =
  let result = Byte_Range_Service.parse_range "bytes=-1500" file_size in
  match result with
    | None -> Lwt.return ()
    | Some _ -> Alcotest.fail "expected None for suffix too large"

let test_parse_range_zero_suffix _switch () =
  let result = Byte_Range_Service.parse_range "bytes=-0" file_size in
  match result with
    | None -> Lwt.return ()
    | Some _ -> Alcotest.fail "expected None for zero suffix"

let test_parse_range_single_byte _switch () =
  let result = Byte_Range_Service.parse_range "bytes=500-500" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 500 range.start;
      Alcotest.(check int) "end_byte" 500 range.end_byte;
      Alcotest.(check int) "total" file_size range.total;
      Lwt.return ()
    | None -> Alcotest.fail "expected valid single byte range"

let test_parse_range_entire_file _switch () =
  let result = Byte_Range_Service.parse_range "bytes=0-999" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 0 range.start;
      Alcotest.(check int) "end_byte" 999 range.end_byte;
      Alcotest.(check int) "total" file_size range.total;
      Lwt.return ()
    | None -> Alcotest.fail "expected valid full file range"

let test_parse_range_last_byte _switch () =
  let result = Byte_Range_Service.parse_range "bytes=-1" file_size in
  match result with
    | Some range ->
      Alcotest.(check int) "start" 999 range.start;
      Alcotest.(check int) "end_byte" 999 range.end_byte;
      Alcotest.(check int) "total" file_size range.total;
      Lwt.return ()
    | None -> Alcotest.fail "expected valid last byte range"

let cases =
  "byte range service", [
    db_test_case "parse range full range" `Quick test_parse_range_full_range;
    db_test_case "parse range from start" `Quick test_parse_range_from_start;
    db_test_case "parse range suffix" `Quick test_parse_range_suffix;
    db_test_case "parse range invalid format" `Quick test_parse_range_invalid_format;
    db_test_case "parse range invalid start end" `Quick test_parse_range_invalid_start_end;
    db_test_case "parse range start greater than end" `Quick test_parse_range_start_greater_than_end;
    db_test_case "parse range out of bounds" `Quick test_parse_range_out_of_bounds;
    db_test_case "parse range negative start" `Quick test_parse_range_negative_start;
    db_test_case "parse range start at file size" `Quick test_parse_range_start_at_file_size;
    db_test_case "parse range suffix too large" `Quick test_parse_range_suffix_too_large;
    db_test_case "parse range zero suffix" `Quick test_parse_range_zero_suffix;
    db_test_case "parse range single byte" `Quick test_parse_range_single_byte;
    db_test_case "parse range entire file" `Quick test_parse_range_entire_file;
    db_test_case "parse range last byte" `Quick test_parse_range_last_byte;
  ]