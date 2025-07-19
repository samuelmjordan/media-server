module type Uuid_Config = sig
  val prefix : string
end

module Make_Uuid(Config : Uuid_Config) = struct
  type uuid = string

  let uuid_length = 36
  let prefix = Config.prefix

  let make () = 
    Config.prefix ^ (Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string)

  let from_string s =
    if not (String.starts_with s ~prefix:Config.prefix) then
      Error (Printf.sprintf "id must start with '%s', got: %s" Config.prefix s)
    else
      let prefix_length = String.length Config.prefix in
      let uuid_part = String.sub s prefix_length (String.length s - prefix_length) in
      if String.length uuid_part <> uuid_length then
        Error (Printf.sprintf "uuid part must be %d chars, got %d in: %s" uuid_length (String.length uuid_part) s)
      else match Uuidm.of_string uuid_part with
      | Some _ -> Ok s
      | None -> Error (Printf.sprintf "invalid uuid format in: %s" s)

  let to_string t = t
end