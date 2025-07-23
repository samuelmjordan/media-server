module File_Uuid = Uuid.Make_Uuid(struct let prefix = "file_" end)

type file = {
  file_id: File_Uuid.uuid;
  path: string;
  name: string;
  mime_type: string;
  is_directory: bool;
  size_bytes: int;
}

let file_to_json file =
  `Assoc [
    ("file_id", `String (File_Uuid.to_string file.file_id));
    ("path", `String file.path);
    ("name", `String file.name);
    ("mime_type", `String file.mime_type);
    ("is_directory", `Bool file.is_directory);
    ("size_bytes", `Int file.size_bytes);
  ]

let make ~path ~name ~is_directory ~size_bytes =
  let mime_type = 
    if is_directory then "inode/directory"
    else match String.rindex_opt name '.' with
      | None -> Mime_types.map_file name
      | Some i -> Mime_types.map_extension (String.sub name (i + 1) (String.length name - i - 1)) in
    {
      file_id = File_Uuid.make ();
      path = path;
      name = name;
      mime_type = mime_type;
      is_directory = is_directory;
      size_bytes = size_bytes;
    }