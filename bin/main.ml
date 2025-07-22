open Nautilus

let () =
  Config.initialize_configs ();
  Dream.run ~port:8080
  @@ Dream.logger  
  @@ Middleware.log_request_headers
  @@ Middleware.log_response_headers
  @@ Dream.router
  @@ Controller.routes