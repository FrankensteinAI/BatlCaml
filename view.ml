open Control
open Format
open Array
open Unix
open Toploop

(* type of datastructure maintained by the view *)
type t = Control.t

let rec printBulletInfo (bl : Control.bulletInfo list) =
	match bl with 
	| [] -> ()
	| h::t -> 
		let own = h.owner in 
		let (xdir, ydir) = h.dir in 
		Format.printf "[BULLET x:%f y:%f dir:(%f,%f) owner:%i] \n" h.x h.y xdir ydir own;
		printBulletInfo t

let rec printBotInfo (bt : Control.botInfo list) =
	match bt with 
	| [] -> ()
	| h::t -> 
		let (xdir, ydir) = h.dir in 
		Format.printf "[BOT x:%f y:%f dir:(%f,%f) power:%f id:%i] \n" h.x h.y xdir ydir h.power h.id;
		printBotInfo t

(* print out the informations *)
let printInfo t =
	print_string "{ FRAME\n";
	t.finished |> string_of_bool |> print_string; print_newline ();
	printBotInfo t.botList;
	printBulletInfo t.bulletList;
	print_endline "}\n"

(* maks a window *)
let initWindow x y =
	Array.make_matrix y x 0 

(* prints an array based on 1s and 0s *)
let printArray a = 
	let size = Array.length a in 
	let size2 = Array.length a.(0) in 
	for i=0 to size-1 do
		for j=0 to size2-1 do
			if a.(i).(j) = 0 
			then print_string " '"
			else if a.(i).(j) = 1
			then print_string " @"
			else print_string " *"
		done;
		print_endline ""
	done;
	print_string "\n\n"

(* equivalent of pressing backspace [num] times *)
let rec backspace (num : int) = 
	match num with
	| 0 -> ()
	| _ -> print_string "\b"; backspace (num-1)

let eval code =
  let as_buf = Lexing.from_string code in
  let parsed = !Toploop.parse_toplevel_phrase as_buf in
  ignore (Toploop.execute_phrase true Format.std_formatter parsed)

(* print out information as dots on a printed grid *)
let printScreen x y (delay : float) (ctrl : Control.t) = 
	let screen = initWindow x y in 
	let size = x in 
	let size2 = y in 
	let rec iter (bots : Control.botInfo list) = (
		match bots with
		| [] -> ()
		| h::t -> 
			let hx = h.x in 
			let hy = h.y in 
			let width = ctrl.width in 
			let height = ctrl.height in 
			let sizef = size-1 |> float_of_int in 
			let sizef2 = size2-1 |> float_of_int in 
			let ratio = sizef /. width in 
			let ratio2 = sizef2 /. height in 
			let hx' = hx *. ratio |> int_of_float in 
			let hy' = hy *. ratio2 |> int_of_float in 
			screen.(hy').(hx') <- 1;
			iter t
	) in 
	let rec iter2 (bullets : Control.bulletInfo list) = (
		match bullets with
		| [] -> () 
		| h::t -> 
			let hx = h.x in 
			let hy = h.y in 
			let width = ctrl.width in 
			let height = ctrl.height in 
			let sizef = size-1 |> float_of_int in 
			let sizef2 = size2-1 |> float_of_int in 
			let ratio = sizef /. width in 
			let ratio2 = sizef2 /. height in 
			let hx' = hx *. ratio |> int_of_float in 
			let hy' = hy *. ratio2 |> int_of_float in 
			screen.(hy').(hx') <- 2;
			iter2 t
	) in
	iter ctrl.botList;
	iter2 ctrl.bulletList;
	eval "backspace (x*y);;";
	eval "Unix.sleepf delay;;";
	eval "printArray screen;;"

(* print out the logs *)
let outputLog t =
  failwith "Unimplemented"

(* entry point for program *)
let main () =
	Control.init ();
	print_string("Enter the number of steps to take as an integer. Enter -1 to simulate until completion: ");
	let printer = printScreen 50 50 0.05 in 
	let count = read_int () in 
	if count < 0
	then
		let t = ref (step ()) in
		while not (!t).finished do
			let _ = printer !t in
			let _ = t := (step ()) in 
			if (!t).finished 
			then let _ = printer !t in ()
			else ()
		done 
	else 
		let t = ref (step ()) in
		for i = 0 to count do
			let _ = printer !t in
			t := (step ());
		done
