open User

let users = ref [
  { userId = "user_1"; name = "alice"; email = "alice@example.com" };
  { userId = "user_2"; name = "bob"; email = "bob@example.com" };
]

let user_to_json user =
  `Assoc [
    ("userId", `String (User.UserUuid.to_string user.userId));
    ("name", `String user.name);
    ("email", `String user.email);
  ]

let json_to_user json =
  let open Yojson.Safe.Util in
  let userId_str = json |> member "userId" |> to_string in
  let name = json |> member "name" |> to_string in
  let email = json |> member "email" |> to_string in
  match User.UserUuid.from_string userId_str with
  | Some userId -> Ok { userId; name; email }
  | None -> Error "invalid userId format"

let getUsers _req =
  let json = `List (List.map user_to_json !users) in
  Dream.json (Yojson.Safe.to_string json)