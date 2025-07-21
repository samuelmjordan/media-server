open Lwt.Syntax
open Alcotest_lwt
open Nautilus

let test_create_and_find _switch () =
  Database_Fixture.cleanup_between_tests ();
  let user_id = User.User_Uuid.make () in
  let* create_result = User_Repository.create ~conn:Database_Fixture.test_provider ~user_id ~name:"alice" ~email:"alice@example.com" () in
  (match create_result with
   | Ok () -> ()
   | Error e -> Alcotest.fail (Caqti_error.show e));
  let* find_result = User_Repository.find_by_id ~conn:Database_Fixture.test_provider ~user_id () in
  match find_result with
  | Ok (Some found_user) ->
    Alcotest.(check string) "name matches" "alice" found_user.name;
    Alcotest.(check string) "email matches" "alice@example.com" found_user.email;
    Lwt.return ()
  | Ok None -> Alcotest.fail "user not found"
  | Error e -> Alcotest.fail e

let test_find_nonexistent _switch () =
  Database_Fixture.cleanup_between_tests ();
  let fake_id = User.User_Uuid.make () in
  let* result = User_Repository.find_by_id ~conn:Database_Fixture.test_provider ~user_id:fake_id () in
  match result with
  | Ok None -> Lwt.return ()
  | Ok (Some _) -> Alcotest.fail "expected no user but found one"
  | Error e -> Alcotest.fail e

let test_find_all _switch () =
  Database_Fixture.cleanup_between_tests ();
  (* create a few users *)
  let user1_id = User.User_Uuid.make () in
  let user2_id = User.User_Uuid.make () in
  let* create1_result = User_Repository.create ~conn:Database_Fixture.test_provider ~user_id:user1_id ~name:"alice" ~email:"alice@example.com" () in
  (match create1_result with Ok () -> () | Error e -> Alcotest.fail (Caqti_error.show e));
  let* create2_result = User_Repository.create ~conn:Database_Fixture.test_provider ~user_id:user2_id ~name:"bob" ~email:"bob@example.com" () in
  (match create2_result with Ok () -> () | Error e -> Alcotest.fail (Caqti_error.show e));
  
  let* result = User_Repository.find_all ~conn:Database_Fixture.test_provider () in
  match result with
  | Ok users ->
    Alcotest.(check int) "has 2 users" 2 (List.length users);
    (* verify users are ordered by created_at (first created comes first) *)
    let names = List.map (fun u -> u.User.name) users in
    Alcotest.(check (list string)) "names in order" ["alice"; "bob"] names;
    Lwt.return ()
  | Error e -> Alcotest.fail (Caqti_error.show e)

let test_find_all_empty _switch () =
  Database_Fixture.cleanup_between_tests ();
  let* result = User_Repository.find_all ~conn:Database_Fixture.test_provider () in
  match result with
  | Ok users -> 
    Alcotest.(check int) "no users found" 0 (List.length users);
    Lwt.return ()
  | Error e -> Alcotest.fail (Caqti_error.show e)

let cases =
  [
    test_case "create and find" `Quick test_create_and_find;
    test_case "find nonexistent" `Quick test_find_nonexistent;
    test_case "find all with data" `Quick test_find_all;
    test_case "find all empty" `Quick test_find_all_empty;
  ]