open Nautilus

let () =
  Config.initialize_configs ();
  Dream.run ~interface:"0.0.0.0" ~port:8080
  @@ Dream.logger  
  @@ Dream.router
  @@ Controller.routes