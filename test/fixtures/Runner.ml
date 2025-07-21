open Nautilus

let () =
  Config.initialize_configs ();
  Lwt_main.run @@ 
  Alcotest_lwt.run "Tests" [
      User_Handler_Test.cases;
      File_Handler_Test.cases;
      File_Repository_Test.cases;
      User_Repository_Test.cases;
    ]