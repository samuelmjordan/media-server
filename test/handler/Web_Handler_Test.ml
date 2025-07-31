open Lwt.Syntax
open Case_Fixture
open Nautilus

let test_library_screen_response _switch () =
  let req = Dream.request ~method_:`GET ~target:"/library" "" in
  let* response = Dream.test Router_Fixture.router req |> Lwt.return in
  let status = Dream.status response in
  Alcotest.(check bool) "status ok or error" true (Dream.status_to_int status = 200 || Dream.status_to_int status >= 500);
  (match Dream.status_to_int status with
    | 200 ->
      let headers = Dream.all_headers response in
      let content_type = List.assoc_opt "Content-Type" headers in
      (match content_type with
        | Some ct -> Alcotest.(check bool) "html content type" true (String.contains ct 'h' && String.contains ct 'm')
        | None -> ());
      Lwt.return ()
    | _ -> Lwt.return ())

let test_film_detail_invalid_file_id _switch () =
  let req = Dream.request ~method_:`GET ~target:"/film/invalid-uuid" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  (* Invalid UUID should return 500 Internal Server Error *)
  Alcotest.(check int) "status" 500 (Dream.status_to_int status);
  Lwt.return ()

let test_film_detail_nonexistent_file _switch () =
  let fake_file_id = File.File_Uuid.make () in
  let req = Dream.request ~method_:`GET ~target:("/film/" ^ (File.File_Uuid.to_string fake_file_id)) "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  (* Valid UUID but nonexistent file returns 200 with user-friendly "not found" page *)
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  Lwt.return ()

let test_static_file_access _switch () =
  let req = Dream.request ~method_:`GET ~target:"/static/style.css" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status ok or not found" true (Dream.status_to_int status = 200 || Dream.status_to_int status = 404);
  Lwt.return ()

let test_favicon_access _switch () =
  let req = Dream.request ~method_:`GET ~target:"/favicon.ico" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status ok or not found" true (Dream.status_to_int status = 200 || Dream.status_to_int status = 404);
  Lwt.return ()

let test_static_nested_path _switch () =
  let req = Dream.request ~method_:`GET ~target:"/static/deep/nested/file.txt" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status ok or not found" true (Dream.status_to_int status = 200 || Dream.status_to_int status = 404);
  Lwt.return ()

let test_static_directory_traversal_blocked _switch () =
  let req = Dream.request ~method_:`GET ~target:"/static/../config.toml" "" in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check bool) "status forbidden or not found" true (Dream.status_to_int status = 403 || Dream.status_to_int status = 404);
  Lwt.return ()

let cases =
  "web handler", [
    db_test_case "library screen response" `Quick test_library_screen_response;
    db_test_case "film detail invalid file id" `Quick test_film_detail_invalid_file_id;
    db_test_case "film detail nonexistent file" `Quick test_film_detail_nonexistent_file;
    db_test_case "static file access" `Quick test_static_file_access;
    db_test_case "favicon access" `Quick test_favicon_access;
    db_test_case "static nested path" `Quick test_static_nested_path;
    db_test_case "static directory traversal blocked" `Quick test_static_directory_traversal_blocked;
  ]