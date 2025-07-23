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