module UserUuid = Uuid.MakeUuid(struct let prefix = "user_" end)

type user = {
  user_id: UserUuid.uuid;
  name: string;
  email: string;
}