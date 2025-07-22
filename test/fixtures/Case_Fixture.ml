open Alcotest_lwt

let with_clean_db test_fn switch () =
  Database_Fixture.cleanup_between_tests ();
  test_fn switch ()

let db_test_case name speed test_fn =
  test_case name speed (with_clean_db test_fn)