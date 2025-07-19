module type UuidConfig = sig
  val prefix : string
end

module MakeUuid(Config : UuidConfig) = struct
  type uuid = string

  let prefix = Config.prefix

  let make () = 
    Config.prefix ^ (Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string)

  let from_string s =
    if not (String.starts_with s ~prefix:Config.prefix) then
      Error (Printf.sprintf "id must start with '%s', got: %s" Config.prefix s)
    else
      let prefix_length = String.length Config.prefix in
      let uuid_part = String.sub s prefix_length (String.length s - prefix_length) in
      match Uuidm.of_string uuid_part with
      | Some _ -> Ok s
      | None -> Error (Printf.sprintf "invalid uuid format in: %s" s)

  let to_string t = t
end