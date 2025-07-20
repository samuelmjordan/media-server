module File_Uuid = Uuid.Make_Uuid(struct let prefix = "file_" end)

type file = {
  file_id: File_Uuid.uuid;
  path: string;
  is_directory: bool;
  size_bytes: int;
}

let file_to_json file =
  `Assoc [
    ("file_id", `String (File_Uuid.to_string file.file_id));
    ("path", `String file.path);
    ("is_directory", `Bool file.is_directory);
    ("size_bytes", `Int file.size_bytes);
  ]