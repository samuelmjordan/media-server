module User_Uuid = Uuid.Make_Uuid(struct let prefix = "user_" end)

type user = {
  user_id: User_Uuid.uuid;
  name: string;
  email: string;
}

let user_to_json user =
  `Assoc [
    ("user_id", `String (User_Uuid.to_string user.user_id));
    ("name", `String user.name);
    ("email", `String user.email);
  ]

let json_to_user json =
  let open Yojson.Safe.Util in
  let user_id_str = json |> member "user_id" |> to_string in
  let name = json |> member "name" |> to_string in
  let email = json |> member "email" |> to_string in
  match User_Uuid.from_string user_id_str with
  | Ok user_id -> Ok { user_id; name; email }
  | Error msg -> Error ("invalid user_id: " ^ msg)

let json_to_user_create json =
  let open Yojson.Safe.Util in
  let name = json |> member "name" |> to_string in
  let email = json |> member "email" |> to_string in
  (name, email)