type db_config = {
  host: string;
  port: int;
  user: string;
  password: string;
  database: string;
}

type tmdb_config = {
  url: string;
  api_key: string;
}

let db_config : db_config option ref = ref None
let tmdb_config : tmdb_config option ref = ref None

let substitute_env_vars content =
  let env_var_pattern = Re.Perl.compile_pat "\\$\\{([A-Z_][A-Z0-9_]*)\\}" in
  Re.replace env_var_pattern content ~f:(fun groups ->
    let var_name = Re.Group.get groups 1 in
    try Sys.getenv var_name
    with Not_found -> failwith ("Environment variable not found: " ^ var_name)
  )

let load_toml_content () =
  let ic = open_in "config.toml" in
  let len = in_channel_length ic in
  let raw_content = really_input_string ic len in
  close_in ic;
  let substituted_content = substitute_env_vars raw_content in
  Printf.printf "substituted toml:\n%s\n%!" substituted_content;
  try
    Otoml.Parser.from_string substituted_content
  with 
  | Otoml__Common.Parse_error (pos_opt, msg) -> 
      let pos_str = match pos_opt with 
        | Some (line, col) -> Printf.sprintf " at line %d, col %d" line col
        | None -> ""
      in
      failwith ("toml parse error" ^ pos_str ^ ": " ^ msg)
  | e -> raise e

let toml_content = lazy (load_toml_content ())

let get_db_config () =
  match !db_config with
  | Some config -> config
  | None ->
    let toml = Lazy.force toml_content in
    let base_path = ["database"] in
    let config = { 
      host = Otoml.find toml Otoml.get_string (base_path @ ["host"]);
      port = Otoml.find toml Otoml.get_integer (base_path @ ["port"]);
      user = Otoml.find toml Otoml.get_string (base_path @ ["user"]);
      password = Otoml.find toml Otoml.get_string (base_path @ ["password"]);
      database = Otoml.find toml Otoml.get_string (base_path @ ["database"]);
    } in
    db_config := Some config;
    config

let get_tmdb_config () =
  match !tmdb_config with
  | Some config -> config
  | None ->
    let toml = Lazy.force toml_content in
    let base_path = ["tmdb"] in
    let config = { 
      url = Otoml.find toml Otoml.get_string (base_path @ ["url"]);
      api_key = Otoml.find toml Otoml.get_string (base_path @ ["api_key"]);
    } in
    tmdb_config := Some config;
    config

let initialize_configs () =
  Printf.printf "loading config...\n%!";
  let _ = get_db_config () in
  let _ = get_tmdb_config () in
  Printf.printf "config loaded ✓\n%!"

let db_uri_from_config config =
  Printf.sprintf "postgresql://%s:%s@%s:%d/%s"
    config.user
    config.password  
    config.host
    config.port
    config.database
  |> Uri.of_string

let get_db_uri () =
  get_db_config () |> db_uri_from_config