open Lwt.Syntax

let library_screen _request =
  let* page = Library_Screen_Service.get_library_screen () in
  match page with
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "failed to fetch page"
    | Ok page -> Dream.html (Format.asprintf "%a" (Tyxml.Html.pp ()) page)

let film_detail request =
  let film_id_str = Dream.param request "file_id" in
  match File.File_Uuid.from_string film_id_str with
  | Error _ -> Dream.respond ~status:`Internal_Server_Error "invalid file id format"
  | Ok file_id ->
    let* page = Film_Detail_Service.get_film_detail_screen file_id in
    match page with
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "internal server error"
    | Ok page -> Dream.html (Format.asprintf "%a" (Tyxml.Html.pp ()) page)