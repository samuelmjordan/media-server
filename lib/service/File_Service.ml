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
  let* _ = File_Repository.delete_by_directory path in
  let rec insert_all = function
    | [] -> Lwt.return (Ok files)
    | file :: rest when not (String.sub file.File.mime_type 0 6 = "video/") ->
        let* result = File_Repository.insert file in
        (match result with
          | Error e -> Lwt.return (Error e)
          | Ok () -> insert_all rest)
    | file :: rest ->
        let parsed_file = Name_Parser_Service.sanitise_filename file.File.name in
        let* result = File_Repository.insert file in
        match result with
          | Error e -> Lwt.return (Error e)
          | Ok () -> 
            let* media_metadata = Tmdb_Client.movie_search file.file_id parsed_file.parsed_name parsed_file.year_opt in
            match media_metadata with
              | None -> insert_all rest
              | Some metadata ->
                let* _ = 
                  let* result = Media_Metadata_Repository.insert metadata in
                  (match result with
                  | Error e -> Lwt_io.eprintf "metadata insert failed: %s\n" e
                  | Ok () -> Lwt.return_unit)
                in
                insert_all rest
  in
  insert_all files

let delete_directory path =
  File_Repository.delete_by_directory path

let get_directory_files ?(path="") ?(mime_filter="") () =
  File_Repository.find_by_directory ~path ~mime_filter ()

let get_file file_id =
  File_Repository.find file_id