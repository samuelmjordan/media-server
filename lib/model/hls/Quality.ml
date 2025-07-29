type t = Q360p | Q480p | Q720p

let quality_of_string = function
  | "360p" -> Ok Q360p
  | "480p" -> Ok Q480p  
  | "720p" -> Ok Q720p
  | _ -> Error "invalid quality"

let string_of_quality = function
  | Q360p -> "360p"
  | Q480p -> "480p"
  | Q720p -> "720p"