let miscRoutes = [
  Dream.get "/" 
    (fun _ -> Dream.html "Good morning, world!");
  Dream.post "/echo" 
    (fun request -> let%lwt body = Dream.body request in Dream.respond ~headers:["Content-Type", "application/octet-stream"] body);
]

let userRoutes = [
  Dream.get "/user" UserHandler.get_all_users;
  Dream.get "/user/:user_id" UserHandler.get_user_by_id;
  Dream.post "/user" UserHandler.create_user;
]

let fileRoutes = [

]

let routes = miscRoutes 
  @ userRoutes 
  @ fileRoutes