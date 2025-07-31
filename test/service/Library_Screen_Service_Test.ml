open Case_Fixture
open Nautilus

let test_normalize_title_for_sorting _switch () =
  let result1 = Library_Screen_Service.normalize_title_for_sorting "The Matrix" in
  Alcotest.(check string) "removes 'The'" "matrix" result1;
  
  let result2 = Library_Screen_Service.normalize_title_for_sorting "Avatar" in
  Alcotest.(check string) "keeps normal title" "avatar" result2;
  
  let result3 = Library_Screen_Service.normalize_title_for_sorting "THE DARK KNIGHT" in
  Alcotest.(check string) "removes 'THE'" "dark knight" result3;
  
  let result4 = Library_Screen_Service.normalize_title_for_sorting "Theory of Everything" in
  Alcotest.(check string) "keeps 'Theory'" "theory of everything" result4;
  
  Lwt.return ()

let test_sort_metadata_alphabetically _switch () =
  let create_metadata title file_id =
    Media_Metadata.make
      ~file_id
      ~adult:false
      ~backdrop_path:""
      ~tmdb_id:0L
      ~original_language:"en"
      ~original_title:title
      ~overview:""
      ~popularity:0.0
      ~poster_path:""
      ~release_date:""
      ~title
      ~video:true
  in
  
  let metadata_list = [
    create_metadata "The Matrix" (File.File_Uuid.make ());
    create_metadata "Avatar" (File.File_Uuid.make ());
    create_metadata "The Dark Knight" (File.File_Uuid.make ());
    create_metadata "Inception" (File.File_Uuid.make ());
    create_metadata "The Avengers" (File.File_Uuid.make ());
  ] in
  
  
  let sorted = Library_Screen_Service.sort_metadata_alphabetically metadata_list in
  let sorted_titles = List.map (fun m -> m.Media_Metadata.title) sorted in
  
  let expected = ["Avatar"; "The Avengers"; "The Dark Knight"; "Inception"; "The Matrix"] in
  Alcotest.(check (list string)) "sorted alphabetically ignoring 'The'" expected sorted_titles;
  
  Lwt.return ()

let cases =
  "library screen service", [
    db_test_case "normalize title for sorting" `Quick test_normalize_title_for_sorting;
    db_test_case "sort metadata alphabetically" `Quick test_sort_metadata_alphabetically;
  ]