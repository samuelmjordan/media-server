open Lwt.Syntax
open Alcotest_lwt
open Nautilus

let verify_user expected actual =
  Alcotest.(check string) "user_id" (User.User_Uuid.to_string expected.User.user_id) (User.User_Uuid.to_string actual.User.user_id);
  Alcotest.(check string) "name" expected.name actual.name;
  Alcotest.(check string) "email" expected.email actual.email

let test_create_and_find _switch () =
  Database_Fixture.cleanup_between_tests ();
  let user = { User.user_id = User.User_Uuid.make (); name = "john"; email = "john@example.com" } in
  let* create_result = User_Repository.create user () in
  (match create_result with
   | Ok () -> ()
   | Error e -> Alcotest.fail (Caqti_error.show e));
  let* find_result = User_Repository.find_by_id user.user_id () in
  match find_result with
  | Ok (Some found_user) ->
    verify_user user found_user;
    Lwt.return ()
  | Ok None -> Alcotest.fail "user not found"
  | Error e -> Alcotest.fail e

let test_find_nonexistent _switch () =
  Database_Fixture.cleanup_between_tests ();
  let fake_id = User.User_Uuid.make () in
  let* result = User_Repository.find_by_id fake_id () in
  match result with
  | Ok None -> Lwt.return ()
  | Ok (Some _) -> Alcotest.fail "expected no user but found one"
  | Error e -> Alcotest.fail e

let test_find_all _switch () =
  Database_Fixture.cleanup_between_tests ();
  (* create a few users *)
  let user1 = { User.user_id = User.User_Uuid.make (); name = "john"; email = "john@example.com" } in
  let user2 = { User.user_id = User.User_Uuid.make (); name = "tom"; email = "tom@example.com" } in
  let* create1_result = User_Repository.create user1 () in
  (match create1_result with Ok () -> () | Error e -> Alcotest.fail (Caqti_error.show e));
  let* create2_result = User_Repository.create user2 () in
  (match create2_result with Ok () -> () | Error e -> Alcotest.fail (Caqti_error.show e));
  
  let* result = User_Repository.find_all () in
  match result with
  | Ok users ->
    Alcotest.(check int) "has 2 users" 2 (List.length users);
    (* verify users are ordered by created_at (first created comes first) *)
    List.iter2 verify_user [user1; user2;] users;
    Lwt.return ()
  | Error e -> Alcotest.fail (Caqti_error.show e)

let test_find_all_empty _switch () =
  Database_Fixture.cleanup_between_tests ();
  let* result = User_Repository.find_all () in
  match result with
  | Ok users -> 
    Alcotest.(check int) "no users found" 0 (List.length users);
    Lwt.return ()
  | Error e -> Alcotest.fail (Caqti_error.show e)

let cases =
  "user repository", [
    test_case "create and find" `Quick test_create_and_find;
    test_case "find nonexistent" `Quick test_find_nonexistent;
    test_case "find all with data" `Quick test_find_all;
    test_case "find all empty" `Quick test_find_all_empty;
  ]