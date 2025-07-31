open Lwt.Syntax
open Case_Fixture
open Nautilus

let test_get_directory_with_path _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/directory?mime=" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  let json = Yojson.Safe.from_string body in
  Alcotest.(check bool) "is list" true (match json with `List _ -> true | _ -> false);
  Lwt.return ()

let test_scan_directory_with_path _switch () =
  let req = Dream.request ~method_:`PATCH ~target:"/api/directory" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status ok or error" true (Dream.status_to_int status = 200);
  Lwt.return ()

let test_delete_directory_nonexistent _switch () =
  (* Delete directory without scanning *)
  let req = Dream.request ~method_:`DELETE ~target:"/api/directory?path=./data" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status 404" true (Dream.status_to_int status = 404);
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
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/file/" ^ (File.File_Uuid.to_string fake_file_id)) "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status not found or error" true (Dream.status_to_int status = 404);
  Lwt.return ()

let test_get_file_existing _switch () =
  let file = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/existing";
    name = "existing.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* _ = File_Repository.insert file in
  let req = Dream.request ~method_:`GET ~target:("/api/file/" ^ (File.File_Uuid.to_string file.file_id)) "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  let json = Yojson.Safe.from_string body in
  let file_id_from_json = json |> Yojson.Safe.Util.member "file_id" |> Yojson.Safe.Util.to_string in
  Alcotest.(check string) "correct file_id" (File.File_Uuid.to_string file.file_id) file_id_from_json;
  Lwt.return ()

let test_get_directory_missing_mime_param _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/directory" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  Alcotest.(check string) "error message" "missing mime param" body;
  Lwt.return ()

let test_get_directory_with_empty_mime _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/directory?mime=" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  let json = Yojson.Safe.from_string body in
  Alcotest.(check bool) "is list" true (match json with `List _ -> true | _ -> false);
  Lwt.return ()

let test_get_directory_with_video_filter _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/directory?mime=video" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  let json = Yojson.Safe.from_string body in
  Alcotest.(check bool) "is list" true (match json with `List _ -> true | _ -> false);
  Lwt.return ()

let test_delete_directory_response _switch () =
  let req = Dream.request ~method_:`DELETE ~target:"/api/directory" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check bool) "status ok or not found" true (Dream.status_to_int status = 200 || Dream.status_to_int status = 404);
  (match Dream.status_to_int status with
    | 200 -> 
      let json = Yojson.Safe.from_string body in
      let deleted_field = json |> Yojson.Safe.Util.member "deleted" in
      Alcotest.(check bool) "has deleted field" true (deleted_field <> `Null);
      Lwt.return ()
    | _ -> Lwt.return ())

let test_delete_directory_uses_config_directory _switch () =
  let req = Dream.request ~method_:`DELETE ~target:"/api/directory" "" in
  let response = Dream.test Router_Fixture.router req in
  let* _ = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check bool) "status ok or not found" true (Dream.status_to_int status = 200 || Dream.status_to_int status = 404);
  Lwt.return ()

let test_scan_directory_success _switch () =
  let req = Dream.request ~method_:`PATCH ~target:"/api/directory" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  let json = Yojson.Safe.from_string body in
  Alcotest.(check bool) "is list" true (match json with `List _ -> true | _ -> false);
  Lwt.return ()

let test_get_file_malformed_uuid _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/file/not-a-uuid-at-all" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  let* body = Dream.body response in
  Alcotest.(check string) "error message" "invalid file id format" body;
  Lwt.return ()

let test_get_file_empty_uuid _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/file/" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status 404 or 400" true (Dream.status_to_int status >= 400 && Dream.status_to_int status < 500);
  Lwt.return ()

let cases =
  "file handler", [
    db_test_case "get directory with path" `Quick test_get_directory_with_path;
    db_test_case "get directory missing mime param" `Quick test_get_directory_missing_mime_param;
    db_test_case "get directory with empty mime" `Quick test_get_directory_with_empty_mime;
    db_test_case "get directory with video filter" `Quick test_get_directory_with_video_filter;
    db_test_case "scan directory with path" `Quick test_scan_directory_with_path;
    db_test_case "scan directory success" `Quick test_scan_directory_success;
    db_test_case "delete directory nonexistent" `Quick test_delete_directory_nonexistent;
    db_test_case "delete directory response" `Quick test_delete_directory_response;
    db_test_case "delete directory uses config directory" `Quick test_delete_directory_uses_config_directory;
    db_test_case "get file invalid id" `Quick test_get_file_invalid_id;
    db_test_case "get file nonexistent" `Quick test_get_file_nonexistent;
  ]