open Yojson.Safe.Util

type media_metadata = {
  file_id: File.File_Uuid.uuid;
  adult: bool;
  backdrop_path: string;
  tmdb_id: int64;
  original_language: string;
  original_title: string;
  overview: string;
  popularity: float;
  poster_path: string;
  release_date: string;
  title: string;
  video: bool;
}

let media_metadata_to_json metadata =
  `Assoc [
    ("file_id", `String (File.File_Uuid.to_string metadata.file_id));
    ("adult", `Bool metadata.adult);
    ("backdrop_path", `String metadata.backdrop_path);
    ("tmdb_id", `Int (Int64.to_int metadata.tmdb_id));
    ("original_language", `String metadata.original_language);
    ("original_title", `String metadata.original_title);
    ("overview", `String metadata.overview);
    ("popularity", `Float metadata.popularity);
    ("poster_path", `String metadata.poster_path);
    ("release_date", `String metadata.release_date);
    ("title", `String metadata.title);
    ("video", `Bool metadata.video);
  ]

let make 
  ~file_id
  ~adult
  ~backdrop_path
  ~tmdb_id 
  ~original_language 
  ~original_title 
  ~overview 
  ~popularity 
  ~poster_path 
  ~release_date 
  ~title 
  ~video =
  {
    file_id;
    adult;
    backdrop_path;
    tmdb_id;
    original_language;
    original_title;
    overview;
    popularity;
    poster_path;
    release_date;
    title;
    video;
  }

let no_metadata file =
  make
  ~file_id:file.File.file_id
  ~adult:false
  ~backdrop_path:"/static/placeholder.svg"
  ~tmdb_id:0L 
  ~original_language:"en" 
  ~original_title:file.name
  ~overview:"" 
  ~popularity:0.0 
  ~poster_path:"/static/placeholder.svg" 
  ~release_date:"" 
  ~title:file.name
  ~video: true

let response_json_to_media_metadata json file_id =
  try
    let adult = json |> member "adult" |> to_bool in
    let backdrop_path = json |> member "backdrop_path" |> to_string_option |> Option.value ~default:"" in
    let tmdb_id = json |> member "id" |> to_int |> Int64.of_int in
    let original_language = json |> member "original_language" |> to_string in
    let original_title = json |> member "original_title" |> to_string in
    let overview = json |> member "overview" |> to_string in
    let popularity = json |> member "popularity" |> to_float in
    let poster_path = json |> member "poster_path" |> to_string_option |> Option.value ~default:"" in
    let release_date = json |> member "release_date" |> to_string in
    let title = json |> member "title" |> to_string in
    let video = json |> member "video" |> to_bool in
    Ok (make 
      ~file_id ~adult ~backdrop_path ~tmdb_id ~original_language 
      ~original_title ~overview ~popularity ~poster_path 
      ~release_date ~title ~video)
  with
  | exn -> Error (Printf.sprintf "parse error: %s" (Printexc.to_string exn))

let get_url_prefix metadata =
  if metadata.tmdb_id = 0L then "" else "https://image.tmdb.org/t/p/w500"

let get_backdrop_url metadata =
  get_url_prefix metadata ^ metadata.backdrop_path

let get_poster_url metadata =
  get_url_prefix metadata ^ metadata.poster_path