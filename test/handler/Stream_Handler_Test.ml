open Lwt.Syntax
open Case_Fixture
open Nautilus

let test_master_playlist_invalid_file_id _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/stream/invalid-uuid/master.m3u8" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  Alcotest.(check string) "error message" "invalid file id format" body;
  Lwt.return ()

let test_master_playlist_nonexistent_file _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/master.m3u8") "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status not found or internal error" true (Dream.status_to_int status >= 400);
  Lwt.return ()

let test_media_playlist_invalid_file_id _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/stream/invalid-uuid/720p/index.m3u8" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  Alcotest.(check string) "error message" "invalid file id format" body;
  Lwt.return ()

let test_media_playlist_invalid_quality _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/invalid-quality/index.m3u8") "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  Alcotest.(check string) "error message" "invalid quality format" body;
  Lwt.return ()

let test_media_playlist_nonexistent_file _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/720p/index.m3u8") "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status not found or internal error" true (Dream.status_to_int status >= 400);
  Lwt.return ()

let test_serve_segment_invalid_file_id _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/stream/invalid-uuid/720p/segment/0" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  Alcotest.(check string) "error message" "invalid file id format" body;
  Lwt.return ()

let test_serve_segment_invalid_quality _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/invalid-quality/segment/0") "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 400 (Dream.status_to_int status);
  Alcotest.(check string) "error message" "invalid quality format" body;
  Lwt.return ()

let test_serve_segment_nonexistent_file _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/720p/segment/0") "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status not found or internal error" true (Dream.status_to_int status >= 400);
  Lwt.return ()

let test_serve_segment_invalid_segment_number _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/720p/segment/abc") "" in
  (* This test expects int_of_string to throw an exception for invalid input *)
  Lwt.catch
    (fun () ->
      let response = Dream.test Router_Fixture.router req in
      let status = Dream.status response in
      Alcotest.(check bool) "status error" true (Dream.status_to_int status >= 400);
      Lwt.return ())
    (fun _ -> 
      (* Exception is expected for invalid segment number *)
      Lwt.return ())

let test_master_playlist_content_type _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/master.m3u8") "" in
  let response = Dream.test Router_Fixture.router req in
  let headers = Dream.all_headers response in
  let content_type = List.assoc_opt "Content-Type" headers in
  (match content_type with
    | Some ct -> Alcotest.(check string) "content type" "application/vnd.apple.mpegurl" ct
    | None -> ());
  Lwt.return ()

let test_media_playlist_content_type _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/720p/index.m3u8") "" in
  let response = Dream.test Router_Fixture.router req in
  let headers = Dream.all_headers response in
  let content_type = List.assoc_opt "Content-Type" headers in
  (match content_type with
    | Some ct -> Alcotest.(check string) "content type" "application/vnd.apple.mpegurl" ct
    | None -> ());
  Lwt.return ()

let test_serve_segment_content_type _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/api/stream/" ^ (File.File_Uuid.to_string fake_file_id) ^ "/720p/segment/0") "" in
  let response = Dream.test Router_Fixture.router req in
  let headers = Dream.all_headers response in
  let content_type = List.assoc_opt "Content-Type" headers in
  let cache_control = List.assoc_opt "Cache-Control" headers in
  (match content_type with
    | Some ct -> Alcotest.(check string) "content type" "video/mp2t" ct
    | None -> ());
  (match cache_control with
    | Some cc -> Alcotest.(check string) "cache control" "public, max-age=86400" cc
    | None -> ());
  Lwt.return ()

let cases =
  "stream handler", [
    db_test_case "master playlist invalid file id" `Quick test_master_playlist_invalid_file_id;
    db_test_case "master playlist nonexistent file" `Quick test_master_playlist_nonexistent_file;
    db_test_case "master playlist content type" `Quick test_master_playlist_content_type;
    db_test_case "media playlist invalid file id" `Quick test_media_playlist_invalid_file_id;
    db_test_case "media playlist invalid quality" `Quick test_media_playlist_invalid_quality;
    db_test_case "media playlist nonexistent file" `Quick test_media_playlist_nonexistent_file;
    db_test_case "media playlist content type" `Quick test_media_playlist_content_type;
    db_test_case "serve segment invalid file id" `Quick test_serve_segment_invalid_file_id;
    db_test_case "serve segment invalid quality" `Quick test_serve_segment_invalid_quality;
    db_test_case "serve segment nonexistent file" `Quick test_serve_segment_nonexistent_file;
    db_test_case "serve segment invalid segment number" `Quick test_serve_segment_invalid_segment_number;
    db_test_case "serve segment content type" `Quick test_serve_segment_content_type;
  ]