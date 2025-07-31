open Lwt.Syntax
open Case_Fixture
open Nautilus

let create_test_metadata file_id =
  Media_Metadata.make
    ~file_id
    ~adult:false
    ~backdrop_path:"/backdrop.jpg"
    ~tmdb_id:12345L
    ~original_language:"en"
    ~original_title:"Test Movie"
    ~overview:"A test movie for unit testing"
    ~popularity:7.5
    ~poster_path:"/poster.jpg"
    ~release_date:"2023-01-01"
    ~title:"Test Movie"
    ~video:false

let verify_metadata expected actual =
  Alcotest.(check string) "file_id" (File.File_Uuid.to_string expected.Media_Metadata.file_id) (File.File_Uuid.to_string actual.Media_Metadata.file_id);
  Alcotest.(check bool) "adult" expected.adult actual.adult;
  Alcotest.(check string) "backdrop_path" expected.backdrop_path actual.backdrop_path;
  Alcotest.(check int64) "tmdb_id" expected.tmdb_id actual.tmdb_id;
  Alcotest.(check string) "original_language" expected.original_language actual.original_language;
  Alcotest.(check string) "original_title" expected.original_title actual.original_title;
  Alcotest.(check string) "overview" expected.overview actual.overview;
  Alcotest.(check (float 0.1)) "popularity" expected.popularity actual.popularity;
  Alcotest.(check string) "poster_path" expected.poster_path actual.poster_path;
  Alcotest.(check string) "release_date" expected.release_date actual.release_date;
  Alcotest.(check string) "title" expected.title actual.title;
  Alcotest.(check bool) "video" expected.video actual.video

let test_insert_and_find _switch () =
  let file_id = File.File_Uuid.make () in
  let file = {
    File.file_id = file_id;
    path = "/test/path";
    name = "test.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* _ = File_Repository.insert file in
  let metadata = create_test_metadata file_id in
  let* insert_result = Media_Metadata_Repository.insert metadata in
  Alcotest.(check (result unit string)) "insert succeeds" (Ok ()) insert_result;
  let* find_result = Media_Metadata_Repository.find file_id in
  match find_result with
    | Error e -> Alcotest.fail e
    | Ok None -> Alcotest.fail "metadata not found"
    | Ok (Some found_metadata) -> 
      verify_metadata metadata found_metadata;
      Lwt.return ()

let test_find_nonexistent _switch () =
  let fake_id = File.File_Uuid.make () in
  let* result = Media_Metadata_Repository.find fake_id in
  match result with
    | Error e -> Alcotest.fail e
    | Ok None -> Lwt.return ()
    | Ok (Some _) -> Alcotest.fail "expected no metadata but found one"

let test_find_all_empty _switch () =
  let* result = Media_Metadata_Repository.find_all () in
  match result with
    | Error e -> Alcotest.fail e
    | Ok metadata_list ->
      Alcotest.(check int) "empty list" 0 (List.length metadata_list);
      Lwt.return ()

let test_find_all_with_data _switch () =
  let file_id1 = File.File_Uuid.make () in
  let file_id2 = File.File_Uuid.make () in
  let file1 = {
    File.file_id = file_id1;
    path = "/test/path1";
    name = "test1.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 1024;
  } in
  let file2 = {
    File.file_id = file_id2;
    path = "/test/path2";
    name = "test2.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 2048;
  } in
  let* _ = File_Repository.insert file1 in
  let* _ = File_Repository.insert file2 in
  let metadata1 = create_test_metadata file_id1 in
  let metadata2 = { (create_test_metadata file_id2) with title = "Second Movie" } in
  let* _ = Media_Metadata_Repository.insert metadata1 in
  let* _ = Media_Metadata_Repository.insert metadata2 in
  let* result = Media_Metadata_Repository.find_all () in
  match result with
    | Error e -> Alcotest.fail e
    | Ok metadata_list ->
      Alcotest.(check int) "list has two items" 2 (List.length metadata_list);
      Lwt.return ()

let test_update_metadata _switch () =
  let file_id = File.File_Uuid.make () in
  let file = {
    File.file_id = file_id;
    path = "/test/update";
    name = "update.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* _ = File_Repository.insert file in
  let original_metadata = create_test_metadata file_id in
  let* _ = Media_Metadata_Repository.insert original_metadata in
  let updated_metadata = { original_metadata with 
    title = "Updated Title"; 
    overview = "Updated overview";
    popularity = 9.0 } in
  let* update_result = Media_Metadata_Repository.update updated_metadata in
  Alcotest.(check (result unit string)) "update succeeds" (Ok ()) update_result;
  let* find_result = Media_Metadata_Repository.find file_id in
  match find_result with
    | Error e -> Alcotest.fail e
    | Ok None -> Alcotest.fail "metadata not found after update"
    | Ok (Some found_metadata) ->
      verify_metadata updated_metadata found_metadata;
      Lwt.return ()

let test_update_nonexistent _switch () =
  let fake_id = File.File_Uuid.make () in
  let fake_metadata = create_test_metadata fake_id in
  let* result = Media_Metadata_Repository.update fake_metadata in
  Alcotest.(check (result unit string)) "update succeeds for nonexistent" (Ok ()) result;
  Lwt.return ()

let test_delete_metadata _switch () =
  let file_id = File.File_Uuid.make () in
  let file = {
    File.file_id = file_id;
    path = "/test/delete";
    name = "delete.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* _ = File_Repository.insert file in
  let metadata = create_test_metadata file_id in
  let* _ = Media_Metadata_Repository.insert metadata in
  let* delete_result = Media_Metadata_Repository.delete file_id in
  Alcotest.(check (result unit string)) "delete succeeds" (Ok ()) delete_result;
  let* find_result = Media_Metadata_Repository.find file_id in
  match find_result with
    | Error e -> Alcotest.fail e
    | Ok None -> Lwt.return ()
    | Ok (Some _) -> Alcotest.fail "metadata should be deleted"

let test_delete_nonexistent _switch () =
  let fake_id = File.File_Uuid.make () in
  let* result = Media_Metadata_Repository.delete fake_id in
  Alcotest.(check (result unit string)) "delete succeeds for nonexistent" (Ok ()) result;
  Lwt.return ()

let test_multiple_metadata_per_file _switch () =
  let file_id = File.File_Uuid.make () in
  let file = {
    File.file_id = file_id;
    path = "/test/multiple";
    name = "multiple.mp4";
    mime_type = "video/mp4";
    is_directory = false;
    size_bytes = 1024;
  } in
  let* _ = File_Repository.insert file in
  let metadata1 = create_test_metadata file_id in
  let metadata2 = { (create_test_metadata file_id) with title = "Different Title" } in
  let* _ = Media_Metadata_Repository.insert metadata1 in
  let* duplicate_result = Media_Metadata_Repository.insert metadata2 in
  match duplicate_result with
    | Error _ -> Alcotest.fail "multiple metadata per file should be allowed"
    | Ok () -> Lwt.return ()

let cases =
  "media metadata repository", [
    db_test_case "insert and find" `Quick test_insert_and_find;
    db_test_case "find nonexistent" `Quick test_find_nonexistent;
    db_test_case "find all empty" `Quick test_find_all_empty;
    db_test_case "find all with data" `Quick test_find_all_with_data;
    db_test_case "update metadata" `Quick test_update_metadata;
    db_test_case "update nonexistent" `Quick test_update_nonexistent;
    db_test_case "delete metadata" `Quick test_delete_metadata;
    db_test_case "delete nonexistent" `Quick test_delete_nonexistent;
    db_test_case "multiple metadata per file" `Quick test_multiple_metadata_per_file;
  ]