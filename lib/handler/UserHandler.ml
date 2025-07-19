open User

let users = ref [
  { userId = User.UserUuid.from_string "user_e48e53ae-bc21-4999-a28e-1941a90cd9f4" |> Result.get_ok; 
    name = "alice"; 
    email = "alice@example.com" };
  { userId = User.UserUuid.from_string "user_88d151f4-fd75-4553-8ea9-572460ceac8a" |> Result.get_ok;
    name = "bob";
    email = "bob@example.com" };
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
  | Ok userId -> Ok { userId; name; email }
  | Error msg -> Error ("invalid userId: " ^ msg)

let getUsers _req =
  let json = `List (List.map user_to_json !users) in
  Dream.json (Yojson.Safe.to_string json)