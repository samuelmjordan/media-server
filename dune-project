(lang dune 3.19)

(name nautilus)

(generate_opam_files true)

(source
 (github jordan12sam/nautilus))

(authors "Sam Jordan <samuelmjordandev@gmail.com>")

(maintainers "Sam Jordan <samuelmjordandev@gmail.com>")

(package
 (name nautilus)
 (synopsis "self hosted media server")
 (depends 
  ocaml dune 
  alcotest alcotest-lwt 
  dream yojson lwt lwt_ppx
  caqti caqti-lwt caqti-driver-postgresql
  otoml uuidm cohttp cohttp-lwt-unix re tyxml ppx_deriving))

(formatting
 (enabled_for ocaml))
