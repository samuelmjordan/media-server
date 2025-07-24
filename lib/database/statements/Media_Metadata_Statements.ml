module Q = struct
  open Caqti_request.Infix
  
  let insert_media_metadata =
    Caqti_type.(t12 File.File_Uuid.caqti_type bool string int64 string string string float string string string bool) ->. Caqti_type.unit
    @@
    "INSERT INTO media_metadata_ (file_id, adult, backdrop_path, tmdb_id, original_language, original_title, overview, popularity, poster_path, release_date, title, video) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

  let get_media_metadata =
    File.File_Uuid.caqti_type ->? Caqti_type.(t12 File.File_Uuid.caqti_type bool string int64 string string string float string string string bool)
    @@
    "SELECT file_id, adult, backdrop_path, tmdb_id, original_language, original_title, overview, popularity, poster_path, release_date, title, video FROM media_metadata_ WHERE file_id = ?"

  let delete_media_metadata =
    File.File_Uuid.caqti_type ->. Caqti_type.unit
    @@
    "DELETE FROM media_metadata_ WHERE file_id = ?"

  let update_media_metadata =
    Caqti_type.(t12 bool string int64 string string string float string string string bool File.File_Uuid.caqti_type) ->. Caqti_type.unit
    @@
    "UPDATE media_metadata_ SET adult = ?, backdrop_path = ?, tmdb_id = ?, original_language = ?, original_title = ?, overview = ?, popularity = ?, poster_path = ?, release_date = ?, title = ?, video = ? WHERE file_id = ?"
end