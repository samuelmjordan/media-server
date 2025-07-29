open Lwt.Syntax
open Media_Metadata
open Tyxml.Html

let get_films_metadata film_file =
  let* metadata = Media_Metadata_Repository.find(film_file.File.file_id) in
  Lwt.return (match metadata with
    | Ok Some m -> m
    | _ -> no_metadata film_file)


let get_film_card metadata =
  a ~a:[a_href ("/film/" ^ metadata.file_id); a_class ["film-card-link"]] [
    div ~a:[a_class ["film-card"]] [
      img ~src:(Media_Metadata.get_poster_url metadata) ~alt:metadata.title ();
      div ~a:[a_class ["film-overlay"]] [
        h3 [txt metadata.title];
        span ~a:[a_class ["year"]] [txt metadata.release_date];
      ];
    ]
  ]

let get_films_grid metadata_list =
  div ~a:[a_class ["films-grid"]] (List.map get_film_card metadata_list)

let get_library_screen () =
  let* film_files = File_Service.get_directory_files ~path:"/home/samuel/jellyfin/data" ~mime_filter:"video" () in
  match film_files with
    | Error e -> Lwt.return (Error e)
    | Ok film_files -> 
      Dream.log "films: %d" (List.length film_files);
      let* film_metadata = Lwt_list.map_p get_films_metadata film_files in
      let page = html
        (head
          (title (txt "Nautilus"))
          [link ~rel:[`Stylesheet] ~href:"/static/style.css" ();
          script ~a:[a_src "https://unpkg.com/htmx.org@1.9.10"] 
            (Unsafe.data "")])
        (body [get_films_grid film_metadata])
      in Lwt.return (Ok page)