let fileRoutes = [
  Dream.get "/api/directory" File_Handler.get_directory;
  Dream.delete "/api/directory" File_Handler.delete_directory;
  Dream.patch "/api/directory" File_Handler.scan_directory;
  Dream.get "/api/file/:file_id" File_Handler.get_file;
]

let streamRoutes = [
  Dream.get "/api/stream/:file_id/master.m3u8" Stream_Handler.master_playlist;
  Dream.get "/api/stream/:file_id/:quality/index.m3u8" Stream_Handler.media_playlist;
  Dream.get "/api/stream/:file_id/:quality/segment/:num" Stream_Handler.serve_segment;
]

let webRoutes = [
  Dream.get "/library" Web_Handler.library_screen;
  Dream.get "/film/:file_id" Web_Handler.film_detail;
  Dream.get "/static/**" (Dream.static "static");
  Dream.get "/favicon.ico" (Dream.from_filesystem "static" "favicon.ico");
]

let routes =
  fileRoutes
  @ streamRoutes
  @ webRoutes