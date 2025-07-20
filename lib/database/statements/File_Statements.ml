module Q = struct
  open Caqti_request.Infix
  
  let insert_file =
    Caqti_type.(t6 File.File_Uuid.caqti_type string string bool bool int) ->. Caqti_type.unit
    @@
    "INSERT INTO file_ (file_id, path, name, is_directory, is_video, size_bytes) VALUES (?, ?, ?, ?, ?, ?)"

  let get_file =
    File.File_Uuid.caqti_type ->? Caqti_type.(t6 File.File_Uuid.caqti_type string string bool bool int)
    @@
    "SELECT file_id, path, name, is_directory, is_video, size_bytes FROM file_ WHERE file_id = ?"
end