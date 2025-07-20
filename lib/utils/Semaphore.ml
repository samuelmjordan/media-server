type t = {
  mutable count: int;
  mutable waiters: unit Lwt.u list;
}

let create n = { count = n; waiters = [] }

let acquire sem =
  if sem.count > 0 then (
    sem.count <- sem.count - 1;
    Lwt.return_unit
  ) else (
    let waiter, wakener = Lwt.wait () in
    sem.waiters <- wakener :: sem.waiters;
    waiter
  )

let release sem =
  sem.count <- sem.count + 1;
  match sem.waiters with
  | [] -> ()
  | wakener :: rest ->
      sem.waiters <- rest;
      sem.count <- sem.count - 1;
      Lwt.wakeup wakener ()