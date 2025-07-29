open Nautilus

let () =
  Config.initialize_configs ();
  Lwt_main.run @@ 
  Alcotest_lwt.run "Tests" [
    File_Handler_Test.cases;
    File_Repository_Test.cases;
  ]