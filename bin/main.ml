open Nautilus

let () =
  Dream.run 
    ~port: 8080
    @@ Dream.logger
    @@ Dream.router 
    @@ Controller.routes