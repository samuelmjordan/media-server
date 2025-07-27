open Lwt.Syntax
open Media_Metadata
open Tyxml.Html

let get_film_metadata film_file =
  let* metadata = Media_Metadata_Repository.find(film_file.File.file_id) in
  Lwt.return (match metadata with
    | Error e -> 
      Dream.log "Error: %s" e;
      Ok (no_metadata film_file)
    | Ok Some m -> Ok m
    | Ok None -> Ok (no_metadata film_file))


let get_film_card film =
  let poster_url_prefix = if film.tmdb_id = 0L then "" else "https://image.tmdb.org/t/p/w500" in
  let poster_url = poster_url_prefix ^ film.Media_Metadata.poster_path in
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

let get_library_screen () =
  let* film_files = File_Service.get_directory_files ~path:"/home/samuel/jellyfin/data" ~mime_filter:"video" () in
  match film_files with
    | Error e -> Lwt.return (Error e)
    | Ok film_files -> 
      Dream.log "films: %d" (List.length film_files);
      let* film_metadata = 
        let* results = Lwt_list.map_s get_film_metadata film_files in
        Lwt.return (List.filter_map Result.to_option results) in
      let page = html
        (head
          (title (txt "Nautilus"))
          [link ~rel:[`Stylesheet] ~href:"/static/style.css" ();
          script ~a:[a_src "https://unpkg.com/htmx.org@1.9.10"] 
            (Unsafe.data "")])
        (body [get_films_grid film_metadata])
      in Lwt.return (Ok page)