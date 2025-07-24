let miscRoutes = [
  Dream.get "/api" 
    (fun _ -> Dream.html "Good morning, world!");
  Dream.post "/api/echo" 
    (fun request -> let%lwt body = Dream.body request in Dream.respond ~headers:["Content-Type", "application/octet-stream"] body);
]

let userRoutes = [
  Dream.get "/api/user" User_Handler.get_all_users;
  Dream.get "/api/user/:user_id" User_Handler.get_user_by_id;
  Dream.post "/api/user" User_Handler.create_user;
]

let fileRoutes = [
  Dream.get "/api/directory" File_Handler.get_directory;
  Dream.delete "/api/directory" File_Handler.delete_directory;
  Dream.patch "/api/directory" File_Handler.scan_directory;
  Dream.get "/api/file/:file_id" File_Handler.get_file;
]

let streamRoutes = [
  Dream.get "/api/stream/:file_id" Stream_Handler.stream_media;
]

let webRoutes = [
  Dream.get "/library" Web_Handler.library_screen;
  Dream.get "/film/:file_id" Web_Handler.film_detail;
  Dream.get "/static/**" (Dream.static "static/");
]

let routes = miscRoutes 
  @ userRoutes 
  @ fileRoutes
  @ streamRoutes
  @ webRoutes