open User

let users = ref [
  { userId = "user_1"; name = "alice"; email = "alice@example.com" };
  { userId = "user_2"; name = "bob"; email = "bob@example.com" };
]

let serialiseUser user =
  `Assoc [
    ("userId", `String user.userId);
    ("name", `String user.name);
    ("email", `String user.email);
  ]

let deserialiseUser json =
  let open Yojson.Safe.Util in
  try
    Ok {
      userId = json |> member "userId" |> to_string;
      name = json |> member "name" |> to_string;
      email = json |> member "email" |> to_string;
    }
  with _ -> Error "invalid json"

let getUsers _req =
  let json = `List (List.map serialiseUser !users) in
  Dream.json (Yojson.Safe.to_string json)