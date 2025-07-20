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
  Dream.post "/directory/scan" File_Handler.scan_directory;
  Dream.get "/file/:file_id" File_Handler.get_file;
]

let streamRoutes = [
  
]

let routes = miscRoutes 
  @ userRoutes 
  @ fileRoutes