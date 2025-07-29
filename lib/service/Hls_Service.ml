open Lwt.Syntax

let master_playlist file_id =
  let* file_result = File_Repository.find file_id in
  match file_result with
  | Error e -> Lwt.return (Error e)
  | Ok None -> Lwt.return (Ok None)
  | Ok Some _ -> 
      let playlist = 
        "#EXTM3U\n#EXT-X-VERSION:3\n" ^
        String.concat "\n" [
          "#EXT-X-STREAM-INF:BANDWIDTH=800000,RESOLUTION=640x360,CODECS=\"avc1.42e00a,mp4a.40.2\"";
          "/api/stream/" ^ file_id ^ "/360p/index.m3u8";
          "#EXT-X-STREAM-INF:BANDWIDTH=1400000,RESOLUTION=854x480,CODECS=\"avc1.42e015,mp4a.40.2\"";
          "/api/stream/" ^ file_id ^ "/480p/index.m3u8";
          "#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1280x720,CODECS=\"avc1.4d401f,mp4a.40.2\"";
          "/api/stream/" ^ file_id ^ "/720p/index.m3u8"
        ]
      in
      Lwt.return (Ok (Some playlist))

let get_segment_count file_id =
  let* file_result = File_Repository.find file_id in
  match file_result with
  | Error e -> Lwt.return (Error e)
  | Ok None -> Lwt.return (Ok None)
  | Ok Some file ->
    let* duration = Ffmpeg.get_video_duration (file.path ^ "/" ^ file.name) in
    match duration with
      | Error e -> Lwt.return (Error e)
      | Ok duration ->
        let segment_duration = 6.0 in
        let count = int_of_float (ceil (duration /. segment_duration)) in
        Lwt.return (Ok (Some count))


let media_playlist file_id quality =
  let* segment_count = get_segment_count file_id in
  match segment_count with
  | Error e -> Lwt.return (Error e)
  | Ok None -> Lwt.return (Ok None)
  | Ok Some count  ->
    let segments = List.init count (fun i ->
      Printf.sprintf "#EXTINF:6.0,\n/api/stream/%s/%s/segment/%d" 
      file_id (Quality.string_of_quality quality) i) in
      let playlist =
      "#EXTM3U\n" ^
      "#EXT-X-VERSION:3\n" ^
      "#EXT-X-TARGETDURATION:7\n" ^
      "#EXT-X-PLAYLIST-TYPE:VOD\n" ^
      "#EXT-X-ALLOW-CACHE:YES\n" ^
      String.concat "\n" segments ^ "\n" ^
      "#EXT-X-ENDLIST\n"
    in
    Lwt.return (Ok (Some playlist))

let ensure_dir_exists dir_path =
  let rec create_parents path =
    if not (Sys.file_exists path) then (
      let parent = Filename.dirname path in
      if parent <> path then create_parents parent;
      Unix.mkdir path 0o755
    ) in
  Lwt.catch
    (fun () ->
      create_parents dir_path;
      Lwt.return ())
    (fun exn ->
      Dream.log "mkdir error: %s" (Printexc.to_string exn);
      Lwt.fail exn)

let get_segment_path file_id quality segment_num =
  let cache_dir = Printf.sprintf "/home/samuel/jellyfin/data/cache/segments/%s/%s" file_id (Quality.string_of_quality quality) in
  let segment_file = Printf.sprintf "%s/segment_%d.ts" cache_dir segment_num in
  
  if Sys.file_exists segment_file then
    Lwt.return (Ok (Some segment_file))
  else
    let* file_result = File_Repository.find file_id in
    match file_result with
    | Error e -> Lwt.return (Error e)
    | Ok None -> Lwt.return (Ok None)
    | Ok Some file ->
      let* () = ensure_dir_exists cache_dir in
      let* () = Ffmpeg.transcode_segment (file.path ^ "/" ^ file.name) segment_num (Quality.string_of_quality quality) segment_file in
      Lwt.return (Ok (Some segment_file))