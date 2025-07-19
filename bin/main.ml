let count = ref 0

let count_requests inner_handler request =
  count := !count + 1;
  inner_handler request

let () =
  Dream.run 
    @@ Dream.logger 
    @@ count_requests
    @@ Dream.router
      [

        Dream.get "/" 
          (fun _ -> Dream.html "Good morning, world!");

        Dream.post "/echo" 
          (fun request -> let%lwt body = Dream.body request in Dream.respond ~headers:["Content-Type", "application/octet-stream"] body);

        Dream.get "/count" 
          (fun _ -> Dream.html (Printf.sprintf "Saw %i request(s)!" !count));

      ]
