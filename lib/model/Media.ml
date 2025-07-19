module MediaUuid = Uuid.MakeUuid(struct let prefix = "media_" end)

type media = {
  mediaId: MediaUuid.t;
  filename: string;
  mime_type: string;
  size_bytes: int;
}