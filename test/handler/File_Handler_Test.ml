open Lwt.Syntax
open Alcotest_lwt
open Nautilus

let test_get_directory_missing_path _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/directory" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  Lwt.return ()

let test_get_directory_with_path _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/directory?path=./data" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  let json = Yojson.Safe.from_string body in
  Alcotest.(check bool) "is list" true (match json with `List _ -> true | _ -> false);
  Lwt.return ()

let test_scan_directory_missing_path _switch () =
  let req = Dream.request ~method_:`POST ~target:"/api/directory/scan" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  Lwt.return ()

let test_scan_directory_with_path _switch () =
  let req = Dream.request ~method_:`POST ~target:"/api/directory/scan?path=./data" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status ok or error" true (Dream.status_to_int status = 200);
  Lwt.return ()

let test_get_file_invalid_id _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/file/not-a-uuid" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  let* body = Dream.body response in
  Alcotest.(check string) "error message" "invalid file id format" body;
  Lwt.return ()

let test_get_file_nonexistent _switch () =
  (* make a valid file uuid that probably doesn't exist *)
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/file/" ^ (File.File_Uuid.to_string fake_file_id)) "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status not found or error" true (Dream.status_to_int status = 404);
  Lwt.return ()

let cases =
  "file handler", [
    test_case "get directory missing path" `Quick test_get_directory_missing_path;
    test_case "get directory with path" `Quick test_get_directory_with_path;
    test_case "scan directory missing path" `Quick test_scan_directory_missing_path;
    test_case "scan directory with path" `Quick test_scan_directory_with_path;
    test_case "get file invalid id" `Quick test_get_file_invalid_id;
    test_case "get file nonexistent" `Quick test_get_file_nonexistent;
  ]