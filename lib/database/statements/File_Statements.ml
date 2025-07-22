module Q = struct
  open Caqti_request.Infix
  
  let insert_file =
    Caqti_type.(t6 File.File_Uuid.caqti_type string string string bool int) ->. Caqti_type.unit
    @@
    "INSERT INTO file_ (file_id, path, name, mime_type, is_directory, size_bytes) VALUES (?, ?, ?, ?, ?, ?)"

  let get_file =
    File.File_Uuid.caqti_type ->? Caqti_type.(t6 File.File_Uuid.caqti_type string string string bool int)
    @@
    "SELECT file_id, path, name, mime_type, is_directory, size_bytes FROM file_ WHERE file_id = ?"

  let find_files_by_directory =
    Caqti_type.(t2 string string) ->* Caqti_type.(t6 File.File_Uuid.caqti_type string string string bool int)
    @@
    "WITH target_path AS (SELECT ? as p)
    SELECT file_id, path, name, mime_type, is_directory, size_bytes
    FROM file_
    WHERE (path = (SELECT p FROM target_path) 
          OR path LIKE (SELECT p FROM target_path) || '/%')
    AND mime_type LIKE (? || '%')"

  let delete_files_by_directory =
    Caqti_type.string ->* Caqti_type.string
    @@
    "WITH target_path AS (SELECT ? as p)
    DELETE FROM file_
    WHERE path = (SELECT p FROM target_path) 
      OR path LIKE (SELECT p FROM target_path) || '/%'
    RETURNING file_id"
end