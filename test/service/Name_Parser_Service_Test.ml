open Case_Fixture
open Nautilus

let test_sanitise_basic_filename _switch () =
  let result = Name_Parser_Service.sanitise_filename "movie.mp4" in
  Alcotest.(check string) "parsed name" "movie" result.Parsed_File.parsed_name;
  Alcotest.(check (option int)) "no year" None result.year_opt;
  Lwt.return ()

let test_sanitise_with_year _switch () =
  let result = Name_Parser_Service.sanitise_filename "The Matrix 1999.mp4" in
  Alcotest.(check string) "parsed name" "The Matrix" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 1999) result.year_opt;
  Lwt.return ()

let test_sanitise_with_quality _switch () =
  let result = Name_Parser_Service.sanitise_filename "Movie 2021 1080p BluRay.mkv" in
  Alcotest.(check string) "parsed name" "Movie" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 2021) result.year_opt;
  Lwt.return ()

let test_sanitise_with_codec _switch () =
  let result = Name_Parser_Service.sanitise_filename "Test.Movie.2020.x264.mp4" in
  Alcotest.(check string) "parsed name" "Test Movie" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 2020) result.year_opt;
  Lwt.return ()

let test_sanitise_with_release_group _switch () =
  let result = Name_Parser_Service.sanitise_filename "Movie Name 2022 [YIFY].mp4" in
  Alcotest.(check string) "parsed name" "Movie Name" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 2022) result.year_opt;
  Lwt.return ()

let test_sanitise_complex_filename _switch () =
  let result = Name_Parser_Service.sanitise_filename "The.Incredible.Movie.2023.1080p.BluRay.x264.DTS-HD.MA.7.1-RARBG.mkv" in
  Alcotest.(check string) "parsed name" "The Incredible Movie" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 2023) result.year_opt;
  Lwt.return ()

let test_sanitise_no_extension _switch () =
  let result = Name_Parser_Service.sanitise_filename "Movie Title 2021" in
  Alcotest.(check string) "parsed name" "Movie Title" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 2021) result.year_opt;
  Lwt.return ()

let test_sanitise_multiple_years _switch () =
  let result = Name_Parser_Service.sanitise_filename "Movie 1999 About 2021.mp4" in
  Alcotest.(check string) "parsed name" "Movie 1999 About" result.parsed_name;
  Alcotest.(check (option int)) "latest year extracted" (Some 2021) result.year_opt;
  Lwt.return ()

let test_sanitise_no_year _switch () =
  let result = Name_Parser_Service.sanitise_filename "Movie.Without.Year.1080p.mp4" in
  Alcotest.(check string) "parsed name" "Movie Without Year" result.parsed_name;
  Alcotest.(check (option int)) "no year" None result.year_opt;
  Lwt.return ()

let test_sanitise_old_year _switch () =
  let result = Name_Parser_Service.sanitise_filename "Classic Movie 1942.mp4" in
  Alcotest.(check string) "parsed name" "Classic Movie" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 1942) result.year_opt;
  Lwt.return ()

let test_sanitise_future_year _switch () =
  let result = Name_Parser_Service.sanitise_filename "Future Movie 2099.mp4" in
  Alcotest.(check string) "parsed name" "Future Movie" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 2099) result.year_opt;
  Lwt.return ()

let test_sanitise_special_characters _switch () =
  let result = Name_Parser_Service.sanitise_filename "Movie-Title_With.Special[Chars](2023).mp4" in
  Alcotest.(check string) "parsed name" "Movie Title With Special Chars" result.parsed_name;
  Alcotest.(check (option int)) "year extracted" (Some 2023) result.year_opt;
  Lwt.return ()

let test_sanitise_empty_filename _switch () =
  let result = Name_Parser_Service.sanitise_filename "" in
  Alcotest.(check string) "empty name" "" result.parsed_name;
  Alcotest.(check (option int)) "no year" None result.year_opt;
  Lwt.return ()

let test_sanitise_only_extension _switch () =
  let result = Name_Parser_Service.sanitise_filename ".mp4" in
  Alcotest.(check string) "empty name" "" result.parsed_name;
  Alcotest.(check (option int)) "no year" None result.year_opt;
  Lwt.return ()

let cases =
  "name parser service", [
    db_test_case "sanitise basic filename" `Quick test_sanitise_basic_filename;
    db_test_case "sanitise with year" `Quick test_sanitise_with_year;
    db_test_case "sanitise with quality" `Quick test_sanitise_with_quality;
    db_test_case "sanitise with codec" `Quick test_sanitise_with_codec;
    db_test_case "sanitise with release group" `Quick test_sanitise_with_release_group;
    db_test_case "sanitise complex filename" `Quick test_sanitise_complex_filename;
    db_test_case "sanitise no extension" `Quick test_sanitise_no_extension;
    db_test_case "sanitise multiple years" `Quick test_sanitise_multiple_years;
    db_test_case "sanitise no year" `Quick test_sanitise_no_year;
    db_test_case "sanitise old year" `Quick test_sanitise_old_year;
    db_test_case "sanitise future year" `Quick test_sanitise_future_year;
    db_test_case "sanitise special characters" `Quick test_sanitise_special_characters;
    db_test_case "sanitise empty filename" `Quick test_sanitise_empty_filename;
    db_test_case "sanitise only extension" `Quick test_sanitise_only_extension;
  ]