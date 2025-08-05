open Lwt.Syntax
open Yojson.Safe.Util

let movie_search_single file_id name year =
  let { Config.url; api_key; } = Config.get_tmdb_config () in
  let headers = Cohttp.Header.add_list (Cohttp.Header.init ()) [
    ("accept", "application/json");
    ("Authorization", api_key);
  ] in
  let uri = Uri.of_string (url ^ "/3/search/movie")
    |> fun u -> Uri.add_query_param u ("query", [name])
    |> fun u -> Uri.add_query_param u ("include_adult", ["true"])
    |> fun u -> match year with
      | Some y -> Uri.add_query_param u ("primary_release_year", [string_of_int y])
      | None -> u in
  let* (resp, body) = Cohttp_lwt_unix.Client.get ~headers uri in
  let status = Cohttp.Response.status resp in
  match Cohttp.Code.code_of_status status with
  | n when n >= 200 && n < 300 ->
    let* body_string = Cohttp_lwt.Body.to_string body in
    let json = Yojson.Safe.from_string body_string in
    let results = json |> member "results" |> to_list in
    (match results with
      | [] -> 
        Dream.log "No matches for: %s (%s)" name (match year with | Some y -> string_of_int y | None -> "no year");
        Lwt.return None
      | first :: _ -> 
        (match Media_Metadata.response_json_to_media_metadata first file_id with
          | Ok metadata -> 
            Dream.log "Found match: %s" name;
            Lwt.return (Some metadata)
          | Error msg -> 
              Dream.log "Media_Metadata parse error: %s" msg;
              Lwt.return None))
  | _ -> 
    let* body_string = Cohttp_lwt.Body.to_string body in
    let status_string = Cohttp.Code.string_of_status status in
    Dream.log "HTTP %s: %s" status_string body_string;
    Lwt.return None

let movie_search file_id name year =
  let title_variations = Name_Parser_Service.generate_title_variations name in
  let rec try_search variations =
    match variations with
    | [] -> Lwt.return None
    | title :: remaining ->
      let* result = match year with
        | Some y -> movie_search_single file_id title (Some y)
        | None -> movie_search_single file_id title None in
      (match result with
        | Some metadata -> Lwt.return (Some metadata)
        | None ->
          (match year with
            | Some _ ->
              let* result_no_year = movie_search_single file_id title None in
              (match result_no_year with
                | Some metadata -> Lwt.return (Some metadata)
                | None -> try_search remaining)
            | None -> try_search remaining))
  in
  
  Dream.log "Trying search with %d title variations for: %s" (List.length title_variations) name;
  try_search title_variations