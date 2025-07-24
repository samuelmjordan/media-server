open Lwt.Syntax
open Media_Metadata

let get_film_card film =
  let poster_url = 
    "https://image.tmdb.org/t/p/w500" ^ film.Media_Metadata.poster_path in
  Tyxml.Html.div ~a:[Tyxml.Html.a_class ["film-card"]] [
    Tyxml.Html.img ~src:poster_url ~alt:film.title ();
    Tyxml.Html.div ~a:[Tyxml.Html.a_class ["film-info"]] [
      Tyxml.Html.h3 [Tyxml.Html.txt film.title];
      Tyxml.Html.p ~a:[Tyxml.Html.a_class ["overview"]] [Tyxml.Html.txt film.overview];
      Tyxml.Html.span ~a:[Tyxml.Html.a_class ["date"]] [Tyxml.Html.txt film.release_date];
    ];
  ]

let get_films_grid films =
  Tyxml.Html.div ~a:[Tyxml.Html.a_class ["films-container"]] 
    (List.map get_film_card films)

let get_library_screen =
  let* films = Media_Metadata_Repository.find_all () in
  match films with
    | Error e -> Lwt.return (Error e)
    | Ok films ->
  let page = Tyxml.Html.html
    (Tyxml.Html.head
      (Tyxml.Html.title (Tyxml.Html.txt "film library"))
      [Tyxml.Html.link ~rel:[`Stylesheet] ~href:"/static/style.css" ();
       Tyxml.Html.script ~a:[Tyxml.Html.a_src "https://unpkg.com/htmx.org@1.9.10"] 
         (Tyxml.Html.Unsafe.data "")])
    (Tyxml.Html.body [get_films_grid films])
  in Lwt.return (Ok page)