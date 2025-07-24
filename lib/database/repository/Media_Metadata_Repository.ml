open Lwt.Syntax

let insert metadata =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec Media_Metadata_Statements.Q.insert_media_metadata 
      (metadata.Media_Metadata.file_id, metadata.adult, metadata.backdrop_path, metadata.tmdb_id, 
       metadata.original_language, metadata.original_title, metadata.overview, metadata.popularity,
       metadata.poster_path, metadata.release_date, metadata.title, metadata.video)) in
  match result with
    | Error e -> Lwt.return (Error (Caqti_error.show e))
    | Ok _ -> Lwt.return (Ok ())

let find file_id =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.find_opt Media_Metadata_Statements.Q.get_media_metadata  file_id) in
  match result with
    | Error e -> Lwt.return (Error (Caqti_error.show e))
    | Ok None -> Lwt.return (Ok None)
    | Ok (Some (file_id, adult, backdrop_path, tmdb_id, original_language, original_title, 
                overview, popularity, poster_path, release_date, title, video)) -> 
      Lwt.return (Ok (Some { 
        Media_Metadata.file_id; adult; backdrop_path; tmdb_id; original_language; 
        original_title; overview; popularity; poster_path; release_date; title; 
        video; 
      }))

let find_all () =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.collect_list Media_Metadata_Statements.Q.get_all_media_metadata ()) in
  match result with
    | Error e -> Lwt.return (Error (Caqti_error.show e))
    | Ok rows -> 
      let media_list = List.map (fun (file_id, adult, backdrop_path, tmdb_id, original_language, original_title, 
                                      overview, popularity, poster_path, release_date, title, video) -> 
        { Media_Metadata.file_id; adult; backdrop_path; tmdb_id; original_language; 
          original_title; overview; popularity; poster_path; release_date; title; 
          video; }) rows in
      Lwt.return (Ok media_list)  

let delete file_id =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec Media_Metadata_Statements.Q.delete_media_metadata  file_id) in
  match result with
    | Error e -> Lwt.return (Error (Caqti_error.show e))
    | Ok _ -> Lwt.return (Ok ())

let update metadata =
  let* result = Db.with_connection (fun (module Db : Caqti_lwt.CONNECTION) ->
    Db.exec Media_Metadata_Statements.Q.update_media_metadata  
      (metadata.Media_Metadata.adult, metadata.backdrop_path, metadata.tmdb_id, 
       metadata.original_language, metadata.original_title, metadata.overview, metadata.popularity,
       metadata.poster_path, metadata.release_date, metadata.title, metadata.video, metadata.file_id)) in
  match result with
    | Error e -> Lwt.return (Error (Caqti_error.show e))
    | Ok _ -> Lwt.return (Ok ())