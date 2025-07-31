open Lwt.Syntax
open Case_Fixture
open Nautilus

let verify_file expected actual =
  Alcotest.(check string) "file_id" (File.File_Uuid.to_string expected.File.file_id) (File.File_Uuid.to_string actual.File.file_id);
  Alcotest.(check string) "path" expected.path actual.path;
  Alcotest.(check string) "name" expected.name actual.name;
  Alcotest.(check string) "mime_type" expected.mime_type actual.mime_type;
  Alcotest.(check bool) "is_directory" expected.is_directory actual.is_directory;
  Alcotest.(check int) "size_bytes" expected.size_bytes actual.size_bytes

let test_insert_and_find _switch () =
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
    | Error e -> Alcotest.fail e
    | Ok None -> Alcotest.fail "file not found"
    | Ok (Some found_file) -> 
  verify_file file found_file;
  Lwt.return ()

let test_find_nonexistent _switch () =
  let fake_id = File.File_Uuid.make () in
  let* result = File_Repository.find fake_id in
  match result with
    | Error e -> Alcotest.fail e
    | Ok None -> Lwt.return ()
    | Ok (Some _) -> Alcotest.fail "expected no file but found one"

let test_find_by_directory_empty _switch () =
  let* result = File_Repository.find_by_directory ~path:"/nonexistent" ~mime_filter:"" () in
  match result with
    | Error e -> Alcotest.fail e
    | Ok files -> 
      Alcotest.(check int) "empty directory" 0 (List.length files);
      Lwt.return ()

let test_find_by_directory_with_files _switch () =
  let file1 = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/dir";
    name = "video.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 2048;
  } in
  let file2 = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/dir";
    name = "audio.mp3";
    mime_type = "audio/mp3";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* _ = File_Repository.insert file1 in
  let* _ = File_Repository.insert file2 in
  let* result = File_Repository.find_by_directory ~path:"/test/dir" ~mime_filter:"" () in
  match result with
    | Error e -> Alcotest.fail e
    | Ok files -> 
      Alcotest.(check int) "two files found" 2 (List.length files);
      Lwt.return ()

let test_find_by_directory_with_mime_filter _switch () =
  let video_file = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/dir";
    name = "video.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 2048;
  } in
  let audio_file = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/dir";
    name = "audio.mp3";
    mime_type = "audio/mp3";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* _ = File_Repository.insert video_file in
  let* _ = File_Repository.insert audio_file in
  let* result = File_Repository.find_by_directory ~path:"/test/dir" ~mime_filter:"video" () in
  match result with
    | Error e -> Alcotest.fail e
    | Ok files -> 
      Alcotest.(check int) "one video file found" 1 (List.length files);
      let found_file = List.hd files in
      Alcotest.(check string) "correct mime type" "video/mp4" found_file.mime_type;
      Lwt.return ()

let test_delete_by_directory_empty _switch () =
  let* result = File_Repository.delete_by_directory "/nonexistent" in
  match result with
    | Error e -> Alcotest.fail e
    | Ok count -> 
      Alcotest.(check int) "no files deleted" 0 count;
      Lwt.return ()

let test_delete_by_directory_with_files _switch () =
  let file1 = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/delete";
    name = "file1.txt";
    mime_type = "text/plain";
    is_directory = false;
    size_bytes = 100;
  } in
  let file2 = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/delete";
    name = "file2.txt";
    mime_type = "text/plain";
    is_directory = false;
    size_bytes = 200;
  } in
  let* _ = File_Repository.insert file1 in
  let* _ = File_Repository.insert file2 in
  let* delete_result = File_Repository.delete_by_directory "/test/delete" in
  match delete_result with
    | Error e -> Alcotest.fail e
    | Ok count -> 
      Alcotest.(check int) "two files deleted" 2 count;
      let* find_result1 = File_Repository.find file1.file_id in
      let* find_result2 = File_Repository.find file2.file_id in
      (match find_result1, find_result2 with
        | Ok None, Ok None -> Lwt.return ()
        | _ -> Alcotest.fail "files should be deleted")

let test_duplicate_insert _switch () =
  let file = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/path";
    name = "duplicate.txt";
    mime_type = "text/plain";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* _ = File_Repository.insert file in
  let* duplicate_result = File_Repository.insert file in
  match duplicate_result with
    | Error _ -> Lwt.return ()
    | Ok () -> Alcotest.fail "duplicate insert should fail"

let test_large_file_handling _switch () =
  let large_file = {
    File.file_id = File.File_Uuid.make ();
    path = "/test/large";
    name = "large_file.bin";
    mime_type = "application/octet-stream";
    is_directory = false;
    size_bytes = max_int;
  } in
  let* insert_result = File_Repository.insert large_file in
  Alcotest.(check (result unit string)) "large file insert succeeds" (Ok ()) insert_result;
  let* find_result = File_Repository.find large_file.file_id in
  match find_result with
    | Error e -> Alcotest.fail e
    | Ok None -> Alcotest.fail "large file not found"
    | Ok (Some found_file) -> 
      verify_file large_file found_file;
      Lwt.return ()

let cases =
  "file repository", [
    db_test_case "insert and find" `Quick test_insert_and_find;
    db_test_case "find nonexistent" `Quick test_find_nonexistent;
    db_test_case "find by directory empty" `Quick test_find_by_directory_empty;
    db_test_case "find by directory with files" `Quick test_find_by_directory_with_files;
    db_test_case "find by directory with mime filter" `Quick test_find_by_directory_with_mime_filter;
    db_test_case "delete by directory empty" `Quick test_delete_by_directory_empty;
    db_test_case "delete by directory with files" `Quick test_delete_by_directory_with_files;
    db_test_case "duplicate insert" `Quick test_duplicate_insert;
    db_test_case "large file handling" `Quick test_large_file_handling;
  ]