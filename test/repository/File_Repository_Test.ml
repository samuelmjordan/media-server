open Lwt.Syntax
open Alcotest_lwt
open Nautilus

let verify_file expected actual =
  Alcotest.(check string) "file_id" (File.File_Uuid.to_string expected.File.file_id) (File.File_Uuid.to_string actual.File.file_id);
  Alcotest.(check string) "path" expected.path actual.path;
  Alcotest.(check string) "name" expected.name actual.name;
  Alcotest.(check string) "mime_type" expected.mime_type actual.mime_type;
  Alcotest.(check bool) "is_directory" expected.is_directory actual.is_directory;
  Alcotest.(check int) "size_bytes" expected.size_bytes actual.size_bytes

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
  let* insert_result = File_Repository.insert file in
  Alcotest.(check (result unit string)) "insert succeeds" (Ok ()) insert_result;
  let* find_result = File_Repository.find file.file_id in
  match find_result with
  | Ok (Some found_file) -> 
    verify_file file found_file;
    Lwt.return ()
  | Ok None -> Alcotest.fail "file not found"
  | Error e -> Alcotest.fail e

let test_find_nonexistent _switch () =
  Database_Fixture.cleanup_between_tests ();
  let fake_id = File.File_Uuid.make () in
  let* result = File_Repository.find fake_id in
  match result with
  | Ok None -> Lwt.return ()
  | Ok (Some _) -> Alcotest.fail "expected no file but found one"
  | Error e -> Alcotest.fail e

let cases =
  "file repository", [
    test_case "insert and find" `Quick test_insert_and_find;
    test_case "find nonexistent" `Quick test_find_nonexistent; 
  ]