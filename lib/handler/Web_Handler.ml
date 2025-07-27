open Lwt.Syntax

let library_screen _request =
  let* page = Library_Screen_Service.get_library_screen () in
  match page with
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "failed to fetch page"
    | Ok page -> Dream.html (Format.asprintf "%a" (Tyxml.Html.pp ()) page)

let film_detail request =
  let film_id = Dream.param request "file_id" in
  let* page = Film_Detail_Service.get_film_detail_screen film_id in
  match page with
  | Error _ -> Dream.respond ~status:`Not_Found "film not found"
  | Ok page -> Dream.html (Format.asprintf "%a" (Tyxml.Html.pp ()) page)