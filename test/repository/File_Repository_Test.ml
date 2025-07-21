open Lwt.Syntax
open Alcotest_lwt
open Nautilus

let test_insert_and_find _switch () =
  Database_Fixture.cleanup_between_tests ();
  let file = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/path";
    name = "test.txt";
    mime_type = "text/plain";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* insert_result = File_Repository.insert ~db_uri:(Some Database_Fixture.test_uri) file in
  Alcotest.(check (result unit string)) "insert succeeds" (Ok ()) insert_result;
  let* find_result = File_Repository.find ~db_uri:(Some Database_Fixture.test_uri) file.file_id in
  match find_result with
  | Ok (Some found_file) -> 
    Alcotest.(check string) "name matches" file.name found_file.name;
    Alcotest.(check string) "path matches" file.path found_file.path;
    Alcotest.(check string) "mime_type matches" file.mime_type found_file.mime_type;
    Alcotest.(check bool) "is_directory matches" file.is_directory found_file.is_directory;
    Alcotest.(check int) "size_bytes matches" file.size_bytes found_file.size_bytes;
    Lwt.return ()
  | Ok None -> Alcotest.fail "file not found"
  | Error e -> Alcotest.fail e

let test_find_nonexistent _switch () =
  Database_Fixture.cleanup_between_tests ();
  let fake_id = File.File_Uuid.make () in
  let* result = File_Repository.find ~db_uri:(Some Database_Fixture.test_uri) fake_id in
  match result with
  | Ok None -> Lwt.return ()
  | Ok (Some _) -> Alcotest.fail "expected no file but found one"
  | Error e -> Alcotest.fail e

let cases =
  [
    test_case "insert and find" `Quick test_insert_and_find;
    test_case "find nonexistent" `Quick test_find_nonexistent; 
  ]