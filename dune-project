(lang dune 3.19)

(name nautilus)

(generate_opam_files true)

(source
 (github jordan12sam/nautilus))

(authors "Sam Jordan <samuelmjordandev@gmail.com>")

(maintainers "Sam Jordan <samuelmjordandev@gmail.com>")

(package
 (name nautilus)
 (depends ocaml dune alcotest alcotest-lwt dream yojson lwt ppx_lwt caqti caqti-lwt caqti-driver-postgresql))

(formatting
 (enabled_for ocaml))
