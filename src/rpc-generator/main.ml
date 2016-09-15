(* $Id$
 *)

let current_line = ref 1;;
let current_column = ref 0;;
let current_file = ref "<stdin>";;

let rec next_token lexbuf =
  let t = Lexer.token lexbuf in
  begin match t with
      Parser.LINEFEED(n,m) ->
	current_line := !current_line + n;
	current_column := m
    | Parser.SETFILE(n,name) ->
	if !current_column <> 0 then raise Lexer.Error;
	current_line := n;
	current_column := 0;
	current_file := name
    | _        ->
	let s = Lexing.lexeme lexbuf in
	current_column := !current_column + (String.length s)
  end;
  match t with
      Parser.LINEFEED(_,_)
    | Parser.IGNORE
    | Parser.SETFILE(_,_) ->
	next_token lexbuf
    | Parser.PERCENT ->
	if !current_column = 1 then begin
	  (match Lexer.ignore_line lexbuf with
	       Parser.LINEFEED(n,m) ->
		 current_line := !current_line + n;
		 current_column := m
             | _ ->
		 let s = Lexing.lexeme lexbuf in
		 current_column := !current_column + (String.length s)
	  );
	  next_token lexbuf
	end
	else
	  raise Lexer.Error
    | _ ->
	t
;;


let read_channel ch =
  let lexbuf = Lexing.from_channel ch in
  current_line := 1;
  current_column := 0;
  try
    Parser.specification next_token lexbuf
  with
      Parsing.Parse_error ->
	Printf.eprintf
	  "In file %s, line %d, column %d: syntax error\n"
	  !current_file
	  !current_line
	  !current_column;
	flush stderr;
	raise Exit
    | Lexer.Error ->
	Printf.eprintf
	  "In file %s, line %d, column %d: lexer error\n"
	  !current_file
	  !current_line
	  !current_column;
	flush stderr;
	raise Exit
;;


let warning f name =
  Format.fprintf f
    ("(************************************************************\n\
   \032* WARNING!\n\
   \032*\n\
   \032* This file is generated by ocamlrpcgen from the source file\n\
   \032* %s\n\
   \032*\n\
   \032************************************************************)@\n")
    name
;;


let main() =
  let targets = ref [] in
  let want_aux = ref false in
  let want_clnt = ref false in
  let want_srv = ref None in
  let clnt_only_functor = ref false in
  let cpp = ref (Some Config.cpp) in
  let cpp_options = ref [] in
  Arg.parse
      [ "-aux",    (Arg.Set want_aux),  " Create file_aux.ml";
	"-clnt",   (Arg.Set want_clnt), " Create file_clnt.ml";
        "-clnt-only-functor", (Arg.Unit (fun () -> 
                                           want_clnt := true;
                                           clnt_only_functor := true)),
        " Create file_clnt.ml but only the functors";
	"-srv",    (Arg.Unit (fun () -> want_srv := Some `Create)),  
	" Create file_srv.ml";
	"-srv2",   (Arg.Unit (fun () -> want_srv := Some `Create2)),  
	" Create file_srv.ml (new style)";

	"-int",
	           (Arg.String
		      (function
			   "abstract" ->
			     Options.default_int_variant   := Syntax.Abstract
			 | "int32" ->
			     Options.default_int_variant   := Syntax.INT32
			 | "unboxed" ->
			     Options.default_int_variant   := Syntax.Unboxed
			 | s ->
			     raise(Arg.Bad "Bad -int"))
		   ),
		   "<v> Set the default variant of the language mapping of int";
	"-hyper",
	           (Arg.String
		      (function
			   "abstract" ->
			     Options.default_hyper_variant := Syntax.Abstract
			 | "int64" ->
			     Options.default_hyper_variant := Syntax.INT64
			 | "unboxed" ->
			     Options.default_hyper_variant := Syntax.Unboxed
			 | s ->
			     raise(Arg.Bad "Bad -hyper"))
		   ),
		   "<v> Set the default variant of the language mapping of hyper";
	"-cpp", (Arg.String
		   (fun s ->
		      cpp := if s = "none" then None else Some s)),
	        "<p> Call the command <p> as preprocessor";
	"-D", (Arg.String (fun s -> cpp_options := !cpp_options @ [ "-D" ^ s ])),
	      "var=value Define the preprocessor variable var";
	"-U", (Arg.String (fun s -> cpp_options := !cpp_options @ [ "-U" ^ s ])),
	      "var Undefine the preprocessor variable var";

	"-I", (Arg.String (fun s -> cpp_options := !cpp_options @ [ "-I" ^ s ])),
	      "path Include this path into the cpp search path";

	"-direct", Arg.Set Options.enable_direct,
	      "  Enable direct mapping";
      ]
      (fun s -> targets := !targets @ [s])
"usage: ocamlrpcgen [-aux] [-clnt] [-srv | -srv2]
                   [-int   (abstract | int32 | unboxed) ]
                   [-hyper (abstract | int64 | unboxed) ]
                   [-cpp   (/path/to/cpp | none) ]
                   [-D var=value]
                   [-U var]
                   [-direct]
                   file.xdr ...";
  List.iter
    (fun target ->
       current_file := target;
       let remove_list = ref [] in
       try
	 let xdr =
	   match !cpp with
	       Some cmd ->
		 let options =
		   String.concat " " (List.map Filename.quote !cpp_options) in
		 Unix.open_process_in (cmd ^ " " ^ options ^ " " ^ target)
	     | None     -> open_in target
	 in
	 let xdr_def = read_channel xdr in
	 (match !cpp with
	      Some _ ->
		let status = Unix.close_process_in xdr in
		if status <> Unix.WEXITED 0 then
		  failwith "Preprocessor failed"
	    | None ->
		close_in xdr
	 );
	 Syntax.resolve_constants xdr_def;
	 Syntax.check_type_constraints xdr_def;
	 Syntax.check_program_definitions xdr_def;
	 Direct.mark_decls_suited_for_direct_mapping xdr_def;
	 Rename.simple_name_mapping xdr_def;
	 let base = Filename.chop_extension target in
	 let auxmodule = String.capitalize (Filename.basename base ^ "_aux") in
	 if !want_aux then begin
	   let auxname = base ^ "_aux.ml" in
	   let auxfile = open_out auxname in
	   remove_list := auxname :: !remove_list;
	   let auxfmt = Format.formatter_of_out_channel auxfile in
	   let auxmliname = base ^ "_aux.mli" in
	   let auxmlifile = open_out auxmliname in
	   remove_list := auxmliname :: !remove_list;
	   let auxmlifmt = Format.formatter_of_out_channel auxmlifile in
	   warning auxfmt target;
	   warning auxmlifmt target;
	   Format.fprintf auxmlifmt "@\n(* Type definitions *)@\n@\n";
	   Generate.output_type_declarations auxfmt xdr_def;
	   Generate.output_type_declarations auxmlifmt xdr_def;
	   Format.fprintf auxmlifmt "@\n(* Constant definitions *)@\n@\n";
	   Generate.output_consts auxmlifmt auxfmt xdr_def;
	   Format.fprintf auxmlifmt "@\n(* Conversion functions *)@\n@\n";
	   Generate.output_conversions auxmlifmt auxfmt xdr_def;
	   Format.fprintf auxmlifmt "@\n(* XDR definitions *)@\n@\n";
	   Generate.output_xdr_type auxmlifmt auxfmt xdr_def;
	   Format.fprintf auxmlifmt "@\n(* Program definitions *)@\n@\n";
	   Generate.output_progdefs auxmlifmt auxfmt xdr_def;
	   close_out auxfile;
	   close_out auxmlifile;
	 end;
	 if !want_clnt then begin
	   (* Clients: *)
	   let clntname = base ^ "_clnt.ml" in
	   let clntfile = open_out clntname in
	   remove_list := clntname :: !remove_list;
	   let clntfmt = Format.formatter_of_out_channel clntfile in
	   let clntmliname = base ^ "_clnt.mli" in
	   let clntmlifile = open_out clntmliname in
	   remove_list := clntmliname :: !remove_list;
	   let clntmlifmt = Format.formatter_of_out_channel clntmlifile in
	   warning clntfmt target;
	   warning clntmlifmt target;
	   Generate.output_client clntmlifmt clntfmt xdr_def
                                  !clnt_only_functor auxmodule;
	   close_out clntfile;
	   close_out clntmlifile;
	 end;
	 ( match !want_srv with
	     | None -> ()
	     | Some style ->
		 (* Servers: *)
		 let srvname = base ^ "_srv.ml" in
		 let srvfile = open_out srvname in
		 remove_list := srvname :: !remove_list;
		 let srvfmt = Format.formatter_of_out_channel srvfile in
		 let srvmliname = base ^ "_srv.mli" in
		 let srvmlifile = open_out srvmliname in
		 remove_list := srvmliname :: !remove_list;
		 let srvmlifmt = Format.formatter_of_out_channel srvmlifile in
		 warning srvfmt target;
		 warning srvmlifmt target;
		 Generate.output_server 
		   style srvmlifmt srvfmt xdr_def auxmodule;
		 close_out srvfile;
		 close_out srvmlifile;
	 )
       with
	   any ->
	     List.iter
	       (fun n -> try Sys.remove n with _ -> ())
	       !remove_list;
	     raise any
    )
    !targets
;;

main();;


