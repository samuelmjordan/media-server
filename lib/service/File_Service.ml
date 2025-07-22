open Lwt.Syntax

let read_directory ?(max_concurrent=200) path =
  let sem = Semaphore.create max_concurrent in
  
  let rec process_path path =
    let* () = Semaphore.acquire sem in
    Lwt.catch
      (fun () ->
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
        
        (* process all entries concurrently *)
        let process_entry entry =
          let full_path = Filename.concat path entry in
          let* stats = Lwt_unix.stat full_path in
          let is_directory = stats.st_kind = S_DIR in
          let file = File.make ~path ~name:entry ~is_directory ~size_bytes:stats.st_size in
          
          if is_directory then
            (* recursively process subdirectory concurrently *)
            let* sub_files = process_path full_path in
            Lwt.return (file :: sub_files)
          else
            Lwt.return [file]
        in
        
        let* results = Lwt_list.map_p process_entry entries in
        Semaphore.release sem;
        Lwt.return (List.concat results)
      )
      (fun exn -> 
        Semaphore.release sem;
        Lwt.fail exn
      )
  in
  process_path path

let scan_directory path =
  let* files = read_directory path in
  let _ = File_Repository.delete_by_directory path in
  let rec insert_all = function
    | [] -> Lwt.return (Ok files)
    | file :: rest ->
        let* result = File_Repository.insert file in
        match result with
        | Ok () -> insert_all rest
        | Error e -> Lwt.return (Error e)
  in
  insert_all files

let delete_directory path =
  File_Repository.delete_by_directory path

let get_directory_files path =
  File_Repository.find_by_directory path

let get_file file_id =
  File_Repository.find file_id