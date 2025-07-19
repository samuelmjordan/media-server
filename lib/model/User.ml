module UserUuid = Uuid.MakeUuid(struct let prefix = "user_" end)

type user = {
  userId: UserUuid.uuid;
  name: string;
  email: string;
}