open Nautilus

let () =
  Config.initialize_configs ();
  Dream.run ~port:8080
  @@ Dream.logger  
  @@ Dream.router
  @@ Controller.routes