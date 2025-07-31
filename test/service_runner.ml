open Nautilus

let () =
  Config.initialize_configs ();
  Alcotest.run "Service Tests" [
    Name_Parser_Service_Test.cases;
    Byte_Range_Service_Test.cases;
  ]