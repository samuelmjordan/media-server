open Str

let sanitise_filename filename =
  let remove_extension s =
    let dot_pos = String.rindex_opt s '.' in
    match dot_pos with
    | Some pos -> String.sub s 0 pos
    | None -> s
  in
  
  let extract_year s =
    let year_regex = regexp {|\b(19[0-9][0-9]|20[0-9][0-9])\b|} in
    try
      let _ = search_forward year_regex s 0 in
      let year_str = matched_string s in
      let year = int_of_string year_str in
      if year >= 1900 && year <= 2030 then Some year else None
    with Not_found -> None
  in
  
  let remove_junk s =
    (* remove common quality/source/codec indicators *)
    let junk_patterns = [
      {|\b(720p|1080p|2160p|4k|480p|BluRay|BRRip|DVDRip|WEBRip|WEB-DL|HDTV|CAM|TS)\b|};
      {|\b(x264|x265|HEVC|H\.264|H\.265|DivX|XviD|AVC)\b|};
      {|\b(AAC|AC3|DTS|MP3|FLAC)\b|};
      {|\[(.*?)\]|}; (* release groups in brackets *)
      {|-[A-Za-z0-9\.]+$|}; (* trailing release group *)
      {|\b(PROPER|REPACK|EXTENDED|UNRATED|Directors?\.Cut)\b|};
    ] in
    List.fold_left (fun acc pattern ->
      global_replace (regexp_case_fold pattern) "" acc
    ) s junk_patterns
  in
  
  let clean_separators s =
    (* convert dots/underscores to spaces, clean up multiple spaces *)
    let s = global_replace (regexp {|[._]|}) " " s in
    let s = global_replace (regexp {| +|}) " " s in
    String.trim s
  in
  
  let truncate_at_year s year_opt =
    match year_opt with
    | None -> s
    | Some year ->
      let year_str = string_of_int year in
      let year_pos = 
        try Some (search_forward (regexp_string year_str) s 0)
        with Not_found -> None
      in
      match year_pos with
      | Some pos -> String.trim (String.sub s 0 pos)
      | None -> s
  in
  
  let s = remove_extension filename in
  let year = extract_year s in
  let s = remove_junk s in
  let s = clean_separators s in
  let s = truncate_at_year s year in
  let s = global_replace (regexp {|^[^a-zA-Z0-9]+|}) "" s in
  let s = global_replace (regexp {|[^a-zA-Z0-9]+$|}) "" s in
  
  { Parsed_File.parsed_name = s; year_opt = year }