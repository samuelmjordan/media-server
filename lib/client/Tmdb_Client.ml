open Lwt.Syntax
open Yojson.Safe.Util

let movie_search file_id name year =
  let { Config.url; api_key; } = Config.get_tmdb_config () in
  let headers = Cohttp.Header.init_with "Authorization" api_key
    |> fun h -> Cohttp.Header.add h "Content-Type" "application/json" in
let uri = 
  let base = Uri.of_string (url ^ "/3/search/movie") in
  Uri.add_query_params base [
    ("query", [name]);
    ("year", [year]);
    ("include_adult", ["false"])
  ] in
  let* (resp, body) = Cohttp_lwt_unix.Client.get ~headers uri in
  let status = Cohttp.Response.status resp in
  match Cohttp.Code.code_of_status status with
  | n when n >= 200 && n < 300 ->
    let* body_string = Cohttp_lwt.Body.to_string body in
    let json = Yojson.Safe.from_string body_string in
    let results = json |> member "results" |> to_list in
    (match results with
     | first :: _ -> Lwt.return (Media_Metadata.response_json_to_media_metadata first file_id)
     | [] -> Lwt.return (Error "no results found"))
  | n ->
    let* error_body = Cohttp_lwt.Body.to_string body in
    Lwt.return (Error (Printf.sprintf "http %d: %s" n error_body))