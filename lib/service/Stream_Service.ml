open Lwt.Syntax

let stream_file_range file_path (range: Byte_Range.t) stream =
  let chunk_size = 64 * 1024 in
  let remaining = ref (range.end_byte - range.start + 1) in
  
  let* ic = Lwt_io.open_file ~mode:Input file_path in
  let* () = Lwt_io.set_position ic (Int64.of_int range.start) in
  
  let rec write_chunks () =
    if !remaining <= 0 then (
      let* () = Lwt_io.close ic in
      Lwt.return ()
    ) else (
      let to_read = min chunk_size !remaining in
      Lwt.catch 
        (fun () ->
          let* chunk = Lwt_io.read ~count:to_read ic in
          let len = String.length chunk in
          remaining := !remaining - len;
          if len = 0 then (
            let* () = Lwt_io.close ic in
            Lwt.return ()
          ) else (
            let* () = Dream.write stream chunk in
            write_chunks ()))
        (fun _exn ->
          let* () = Lwt_io.close ic in
          Lwt.return ())) in
  
  write_chunks ()

let stream_whole_file file_path stream =
  let chunk_size = 64 * 1024 in
  let* ic = Lwt_io.open_file ~mode:Input file_path in
  
  let rec write_chunks () =
    Lwt.catch
      (fun () ->
        let* chunk = Lwt_io.read ~count:chunk_size ic in
        if String.length chunk = 0 then (
          let* () = Lwt_io.close ic in
          Lwt.return ()
        ) else (
          let* () = Dream.write stream chunk in
          write_chunks ()))
      (fun _exn ->
        let* () = Lwt_io.close ic in
        Lwt.return ()) in
  
  write_chunks ()