module File_Uuid = Uuid.Make_Uuid(struct let prefix = "file_" end)

type file = {
  file_id: File_Uuid.uuid;
  path: string;
  name: string;
  is_directory: bool;
  is_video: bool;
  size_bytes: int;
}

let file_to_json file =
  `Assoc [
    ("file_id", `String (File_Uuid.to_string file.file_id));
    ("path", `String file.path);
    ("name", `String file.name);
    ("is_directory", `Bool file.is_directory);
    ("is_video", `Bool file.is_video);
    ("size_bytes", `Int file.size_bytes);
  ]

let is_video filename =
  let ext = Filename.extension filename |> String.lowercase_ascii in
  match ext with
  | ".mp4" | ".avi" | ".mkv" | ".mov" | ".wmv" | ".flv" | ".webm" | ".m4v" -> true
  | _ -> false

let make ~path ~name ~is_directory ~size_bytes =
  {
    file_id = File_Uuid.make ();
    path = path;
    name = name;
    is_directory = is_directory;
    is_video = is_video name;
    size_bytes = size_bytes;
  }