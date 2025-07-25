open Lwt.Syntax
open Media_Metadata
open Tyxml.Html

let get_film_card film =
  let poster_url = 
    "https://image.tmdb.org/t/p/w500" ^ film.Media_Metadata.poster_path in
  a ~a:[a_href ("/film/" ^ film.file_id); a_class ["film-card-link"]] [
    div ~a:[a_class ["film-card"]] [
      img ~src:poster_url ~alt:film.title ();
      div ~a:[a_class ["film-overlay"]] [
        h3 [txt film.title];
        span ~a:[a_class ["year"]] [txt film.release_date];
      ];
    ]
  ]

let get_films_grid films =
  div ~a:[a_class ["films-grid"]] (List.map get_film_card films)

let get_library_screen =
  let* films = Media_Metadata_Repository.find_all () in
  match films with
    | Error e -> Lwt.return (Error e)
    | Ok films ->
  let page = html
    (head
      (title (txt "Nautilus"))
      [link ~rel:[`Stylesheet] ~href:"/static/style.css" ();
       script ~a:[a_src "https://unpkg.com/htmx.org@1.9.10"] 
         (Unsafe.data "")])
    (body [get_films_grid films])
  in Lwt.return (Ok page)