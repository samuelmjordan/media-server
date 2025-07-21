let () =
  Lwt_main.run @@ 
  Alcotest_lwt.run "File Repository" [
      "file ops", File_Repository_Test.cases;
      "user ops", User_Repository_Test.cases;
    ]