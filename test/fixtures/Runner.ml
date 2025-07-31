open Nautilus

let () =
  Config.initialize_configs ();
  Lwt_main.run @@ 
  Alcotest_lwt.run "Tests" [
    File_Handler_Test.cases;
    Stream_Handler_Test.cases;
    Web_Handler_Test.cases;
    File_Repository_Test.cases;
    Media_Metadata_Repository_Test.cases;
    Name_Parser_Service_Test.cases;
    Byte_Range_Service_Test.cases;
  ]