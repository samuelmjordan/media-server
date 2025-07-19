module Media_Uuid = Uuid.Make_Uuid(struct let prefix = "media_" end)

type media = {
  mediaId: Media_Uuid.uuid;
  filename: string;
  mime_type: string;
  size_bytes: int;
}