open Lwt.Syntax

let rec read_dir path =
  let* handle = Lwt_unix.opendir path in
  let rec loop acc =
    try%lwt
      let* entry = Lwt_unix.readdir handle in
      if entry = "." || entry = ".." then
        loop acc
      else
        let full_path = Filename.concat path entry in
        let* stats = Lwt_unix.stat full_path in
        let is_directory = stats.st_kind = S_DIR in
        let size_bytes = stats.st_size in
        let file = File.make ~path ~name:entry ~is_directory ~size_bytes in
        let acc = file :: acc in
        if is_directory then
          let* sub_files = read_dir full_path in
          loop (sub_files @ acc)
        else
          loop acc
    with 
      | End_of_file ->
        let* () = Lwt_unix.closedir handle in
        Lwt.return (List.rev acc)
      | _ -> loop acc
  in 
  loop []