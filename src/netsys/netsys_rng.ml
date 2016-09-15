(* $Id$ *)

let default_rng() =
  match Sys.os_type with
    | "Win32" ->
	Netsys_win32.fill_random

    | "Unix" | "Cygwin" ->
	(fun s ->
	   let fd = Unix.openfile "/dev/urandom" [Unix.O_RDONLY] 0 in
	   try
	     Netsys.really_gread `Read_write fd s 0 (Bytes.length s);
	     Unix.close fd
	   with e -> Unix.close fd; raise e
	)

    | _ ->
	failwith "Netsys_rng: No default secure random number generator"

let rng = ref (default_rng())

let set_rng r = rng := r

let fill_random s = !rng s
