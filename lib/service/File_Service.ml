open Lwt.Syntax

let split_n n lst =
  let rec aux acc i = function
    | [] -> (List.rev acc, [])
    | x :: xs when i > 0 -> aux (x :: acc) (i - 1) xs
    | rest -> (List.rev acc, rest)
  in
  aux [] n lst

(* semaphore to limit concurrent operations *)
module Semaphore = struct
  type t = {
    mutable count: int;
    mutable waiters: unit Lwt.u list;
  }
  
  let create n = { count = n; waiters = [] }
  
  let acquire sem =
    if sem.count > 0 then (
      sem.count <- sem.count - 1;
      Lwt.return_unit
    ) else (
      let waiter, wakener = Lwt.wait () in
      sem.waiters <- wakener :: sem.waiters;
      waiter
    )
  
  let release sem =
    sem.count <- sem.count + 1;
    match sem.waiters with
    | [] -> ()
    | wakener :: rest ->
        sem.waiters <- rest;
        sem.count <- sem.count - 1;
        Lwt.wakeup wakener ()
end

let read_dir ?(max_concurrent=200) path =
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