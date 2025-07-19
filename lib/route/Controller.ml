let miscRoutes = [
  Dream.get "/" 
    (fun _ -> Dream.html "Good morning, world!");
  Dream.post "/echo" 
    (fun request -> let%lwt body = Dream.body request in Dream.respond ~headers:["Content-Type", "application/octet-stream"] body);
]

let userRoutes = [
  Dream.get "/users" UserHandler.getUsers;
]

let fileRoutes = [

]

let routes = miscRoutes 
  @ userRoutes 
  @ fileRoutes