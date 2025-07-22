open Lwt.Syntax
open Case_Fixture
open Nautilus

let verify_user expected actual =
  Alcotest.(check string) "user_id" (User.User_Uuid.to_string expected.User.user_id) (User.User_Uuid.to_string actual.User.user_id);
  Alcotest.(check string) "name" expected.name actual.name;
  Alcotest.(check string) "email" expected.email actual.email

let test_get_all_users _switch () =
  let req = Dream.request ~method_:`GET ~target:"/api/user" "" in
  let response = Dream.test Router_Fixture.router req in
  let* body = Dream.body response in
  let status = Dream.status response in
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  let json = Yojson.Safe.from_string body in
  Alcotest.(check bool) "is list" true (match json with `List _ -> true | _ -> false);
  Lwt.return ()

let test_create_user _switch () =
  let user_json = `Assoc [("name", `String "test user"); ("email", `String "test@example.com")] in
  let body = Yojson.Safe.to_string user_json in
  let req = Dream.request ~method_:`POST ~target:"/api/user" body in
  let response = Dream.test Router_Fixture.router req in
  let status = Dream.status response in
  Alcotest.(check int) "status" 200 (Dream.status_to_int status);
  let* resp_body = Dream.body response in
  let json = Yojson.Safe.from_string resp_body in
  match User.json_to_user json with
  | Error msg -> Alcotest.fail ("failed to parse actual user: " ^ msg)
  | Ok actual -> 
    Alcotest.(check string) "name" "test user" actual.name;
    Alcotest.(check string) "email" "test@example.com" actual.email;
    Lwt.return ()

let test_get_user_by_id _switch () =
  let user_json = `Assoc [("name", `String "fetch test"); ("email", `String "fetch@example.com")] in
  let body = Yojson.Safe.to_string user_json in
  let req = Dream.request ~method_:`POST ~target:"/api/user" body in
  let create_response = Dream.test Router_Fixture.router req in
  let* create_body = Dream.body create_response in
  let created_json = Yojson.Safe.from_string create_body in
  match User.json_to_user created_json with
  | Error msg -> Alcotest.fail ("failed to parse created user: " ^ msg)
  | Ok created_user -> 
    let get_req = Dream.request ~method_:`GET ~target:("/api/user/" ^ (User.User_Uuid.to_string created_user.user_id)) "" in
    let get_response = Dream.test Router_Fixture.router get_req in
    let* get_body = Dream.body get_response in
    let get_json = Yojson.Safe.from_string get_body in
    let status = Dream.status get_response in
    Alcotest.(check int) "status" 200 (Dream.status_to_int status);
    match User.json_to_user get_json with
    | Error msg -> Alcotest.fail ("failed to parse actual user: " ^ msg)
    | Ok actual -> 
      Alcotest.(check string) "name" "fetch test" actual.name;
      Alcotest.(check string) "email" "fetch@example.com" actual.email;
      Lwt.return ()

  let cases =
    "user handler", [
    db_test_case "get all users" `Quick test_get_all_users;
    db_test_case "create user" `Quick test_create_user;
    db_test_case "get user by id" `Quick test_get_user_by_id;
  ]