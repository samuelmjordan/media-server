open Lwt.Syntax

let library_screen _request =
  let* page = Library_Screen_Service.get_library_screen in
  match page with
    | Error _ -> Dream.respond ~status:`Internal_Server_Error "failed to fetch page"
    | Ok page -> Dream.html (Format.asprintf "%a" (Tyxml.Html.pp ()) page)