module UserUuid = struct
  type t = string
  
  let make () = 
    "user_" ^ (Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string)
  
  let from_string s =
    if String.starts_with s ~prefix:"user_" && String.length s = 41 then
      Some s
    else
      None
  
  let to_string t = t
end

type user = {
  userId: UserUuid.t;
  name: string;
  email: string;
}