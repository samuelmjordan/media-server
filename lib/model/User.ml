module User_Uuid = Uuid.Make_Uuid(struct let prefix = "user_" end)

type user = {
  user_id: User_Uuid.uuid;
  name: string;
  email: string;
}