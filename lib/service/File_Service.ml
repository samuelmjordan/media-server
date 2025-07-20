open Lwt.Syntax

let rec read_dir path =
  let* handle = Lwt_unix.opendir path in
  let rec collect_entries acc =
    try%lwt
      let* entry = Lwt_unix.readdir handle in
      if entry = "." || entry = ".." then
        collect_entries acc
      else
        collect_entries (entry :: acc)
    with End_of_file -> Lwt.return acc
  in
  let* entries = collect_entries [] in
  let* () = Lwt_unix.closedir handle in
  let process_entry entry =
    let full_path = Filename.concat path entry in
    let* stats = Lwt_unix.stat full_path in
    let is_directory = stats.st_kind = S_DIR in
    let file = File.make ~path ~name:entry ~is_directory ~size_bytes:stats.st_size in
    if is_directory then
      let* sub_files = read_dir full_path in
      Lwt.return (file :: sub_files)
    else
      Lwt.return [file]
  in
  let* results = Lwt_list.map_p process_entry entries in
  Lwt.return (List.concat results)