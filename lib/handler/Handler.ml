let with_query_param req param_name f =
  match Dream.query req param_name with
  | None -> Dream.json ~status:`Bad_Request ("missing " ^ param_name ^ " param")
  | Some value -> f value