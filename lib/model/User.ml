module UserUuid = Uuid.MakeUuid(struct let prefix = "user_" end)

type user = {
  userId: UserUuid.t;
  name: string;
  email: string;
}