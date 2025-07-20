let miscRoutes = [
  Dream.get "/" 
    (fun _ -> Dream.html "Good morning, world!");
  Dream.post "/echo" 
    (fun request -> let%lwt body = Dream.body request in Dream.respond ~headers:["Content-Type", "application/octet-stream"] body);
]

let userRoutes = [
  Dream.get "/user" User_Handler.get_all_users;
  Dream.get "/user/:user_id" User_Handler.get_user_by_id;
  Dream.post "/user" User_Handler.create_user;
]

let fileRoutes = [
  Dream.get "/directory" File_Handler.get_directory;
]

let streamRoutes = [
  Dream.get "/stream/:id" Stream_Handler.stream_media;
]

let routes = miscRoutes 
  @ userRoutes 
  @ fileRoutes
  @ streamRoutes