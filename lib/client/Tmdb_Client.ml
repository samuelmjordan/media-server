open Lwt.Syntax
open Yojson.Safe.Util

let movie_search file_id name year =
  let { Config.url; api_key; } = Config.get_tmdb_config () in
  api_key |> ignore;
  let headers = Cohttp.Header.add_list (Cohttp.Header.init ()) [
    ("accept", "application/json");
    ("Authorization", "Bearer eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiI5ZTAyYTFjMmJhMDI0YmYwMmFmMzU0MTcwMDlhMTg0MiIsIm5iZiI6MTc1MzIxNTgyNy41Mzc5OTk5LCJzdWIiOiI2ODdmZjM1MzZhMzgwNGMyMGUxNmFiZDkiLCJzY29wZXMiOlsiYXBpX3JlYWQiXSwidmVyc2lvbiI6MX0.I5kqJh6B5GAnd9-PNvLEZXdHz5nMCyTiAClhxGwIm8g");
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
        Dream.log "No matches";
        Lwt.return None
      | first :: _ -> 
        (match Media_Metadata.response_json_to_media_metadata first file_id with
          | Ok metadata -> Lwt.return (Some metadata)
          | Error _ -> Lwt.return None))
  | _ -> 
    let* body_string = Cohttp_lwt.Body.to_string body in
    let status_string = Cohttp.Code.string_of_status status in
    Dream.log "HTTP %s: %s" status_string body_string;
    Lwt.return None