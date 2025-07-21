let () =
  Database_Fixture.setup_once ();
  Lwt_main.run @@ 
  Alcotest_lwt.run "File Repository" ["basic ops", File_Repository_Test.cases;]