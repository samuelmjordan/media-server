let split_camel_case text =
  Re.replace (Re.Perl.compile_pat "([a-z])([A-Z])") ~f:(fun g -> Re.Group.get g 1 ^ " " ^ Re.Group.get g 2) text

let generate_title_variations title =
  let words = String.split_on_char ' ' title in
  let rec take n lst =
    if n <= 0 then []
    else match lst with
      | [] -> []
      | x :: xs -> x :: take (n - 1) xs
  in
  let rec build_variations acc word_count =
    if word_count <= 0 then acc
    else
      let current_title = String.concat " " (take word_count words) |> String.trim in
      if current_title <> "" then
        build_variations (current_title :: acc) (word_count - 1)
      else
        build_variations acc (word_count - 1)
  in
  let word_count = List.length words in
  let variations = build_variations [] word_count in
  List.rev (List.sort_uniq String.compare (List.filter (fun s -> String.trim s <> "") variations))

let sanitise_filename filename =
 let filename = 
   match String.rindex_opt filename '.' with
   | Some pos -> String.sub filename 0 pos
   | None -> filename in
 let filename = split_camel_case filename in
 let year_regex = Re.Perl.compile_pat "\\b(19[0-9]{2}|20[0-9]{2})\\b" in
 let filename = Re.replace_string (Re.Perl.compile_pat "[-._/,()\\[\\]{}]+") ~by:" " filename in
 let year_opt, filename = 
   try 
     let matches = Re.all year_regex filename in
     match List.rev matches with
     | last_match :: _ ->
         let year = int_of_string (Re.Group.get last_match 1) in
         let year_pos = Re.Group.start last_match 1 in
         let clean_name = String.sub filename 0 year_pos in
         Some year, clean_name
     | [] -> raise Not_found
   with Not_found -> 
     let patterns = [
       "\\[.*?\\]";
       "\\b(480p|576p|720p|1080p|2160p|4k|8k)\\b";
       "\\b(blu.?ray|br.?rip|dvd.?rip|web.?rip|web.?dl|hdtv|cam|ts|r5|screener)\\b";
       "\\b(x264|x265|hevc|h264|h265|avc|divx|xvid)\\b";
       "\\b(aac|ac3|dts|mp3|flac|truehd|atmos|ddp?[0-9.]+)\\b";
       "\\b(proper|repack|extended|directors.?cut|theatrical|limited)\\b";
       "\\b(yify|yts|rarbg|1337x|eztv|sparks|tigole|kingdom)\\b";
       "\\b(subs?|dubs?|multisubs?)\\b";
       "\\b([0-9]+bit)\\b";
     ] in
     let cleaned = List.fold_left (fun acc pattern -> 
       let result = Re.replace_string (Re.Perl.compile_pat ~opts:[`Caseless] pattern) ~by:"" acc in
       if result <> acc then Dream.log "Pattern '%s' matched in '%s' -> '%s'" pattern acc result;
       result
     ) filename patterns in
     None, cleaned in
 let filename = filename in
 let filename = 
   Re.replace_string (Re.Perl.compile_pat "\\s+") ~by:" " filename in
 let filename = String.trim filename in

 Dream.log "clean name: %s :: year: %s" filename (match year_opt with | Some y -> string_of_int y | None -> "");
 { Parsed_File.parsed_name = filename; year_opt = year_opt }