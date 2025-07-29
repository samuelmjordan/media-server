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