type db_config = {
  host: string;
  port: int;
  user: string;
  password: string;
  database: string;
} [@@deriving show]

(* just use a ref since there's only one config now *)
let cached_config : db_config option ref = ref None

let load_toml_content () =
  let ic = open_in "config.toml" in
  let len = in_channel_length ic in
  let content = really_input_string ic len in
  close_in ic;
  Otoml.Parser.from_string content

let toml_content = lazy (load_toml_content ())

let get_db_config () =
  match !cached_config with
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
    cached_config := Some config;
    config

(* preload config at startup *)
let initialize_configs () =
  Printf.printf "loading config...\n%!";
  let config = get_db_config () in
  Printf.printf "%s\n%!" (show_db_config config);
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