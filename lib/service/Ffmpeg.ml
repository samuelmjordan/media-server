open Lwt.Syntax

let get_video_duration file_path =
  let cmd = [|
    "ffprobe"; 
    "-v"; "error";
    "-show_entries"; "format=duration";
    "-of"; "csv=p=0";
    file_path
  |] in
  Lwt.catch
    (fun () ->
      let* stdout = Lwt_process.pread ("ffprobe", cmd) in
      let duration_str = String.trim stdout in
      if duration_str = "" then
        Lwt.return (Error "no output from ffprobe")
      else
        (match Float.of_string_opt duration_str with
        | Some duration -> Lwt.return (Ok duration)
        | None -> Lwt.return (Error ("invalid duration: " ^ duration_str))))
    (fun _ -> Lwt.return (Error "ffprobe failed"))

let transcode_segment input_file segment_num quality output_file =
  let segment_duration = 6.0 in
  let start_time = float_of_int segment_num *. segment_duration in
  let ts_offset = start_time in
  let quality_args = match quality with
    | "360p" -> ["-s"; "640x360"; "-b:v"; "800k"]
    | "480p" -> ["-s"; "854x480"; "-b:v"; "1400k"] 
    | "720p" -> ["-s"; "1280x720"; "-b:v"; "2800k"]
    | _ -> ["-b:v"; "1400k"] in
  let cmd = Array.of_list ([
    "ffmpeg"; "-y";
    "-ss"; string_of_float start_time;
    "-i"; input_file;
    "-t"; string_of_float segment_duration;
    "-c:v"; "libx264"; 
    "-preset"; "ultrafast";
    "-c:a"; "aac";
    "-muxdelay"; "0";
    "-muxpreload"; "0";
    "-output_ts_offset"; string_of_float ts_offset;
  ] @ quality_args @ [
    "-f"; "mpegts";
    output_file
  ]) in
  
  Dream.log "transcoding: seg_%d %s %s" segment_num quality input_file;
  Lwt.catch
    (fun () ->
      let* _output = Lwt_process.pread ~stderr:`Dev_null ("ffmpeg", cmd) in
      if Sys.file_exists output_file then
        Lwt.return ()
      else
        Lwt.fail (Failure "segment generation failed"))
    (fun exn ->
      Dream.log "ffmpeg error: %s" (Printexc.to_string exn);
      Lwt.fail exn)