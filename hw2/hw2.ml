(* convert grammar: grammar2 is start_sym, production for each nonterminal given matching function *)
let rec build_productions nonterm grammar =
    match grammar with
    [] -> []
    | (curr_nonterm, rhs)::t -> if curr_nonterm = nonterm then rhs::(build_productions nonterm t) else (build_productions nonterm t)
    ;;
let convert_grammar gram1 =
    ((fst gram1), fun nonterm -> build_productions nonterm (snd gram1))
    ;;



type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal


(* helper functions *)

(* old implementation of matcher (from TA)
(* k should be something else *)
let rec matcher acceptor derivation frag =
  match (acceptor derivation frag) with
    None ->
        (if k = 0 then None
        else match frag with
        | [] -> None
        | rule::t -> matcher acceptor derivation@[rule] t)
    | x -> x  (* done matcher has returned a value *)
  ;;
  *)



(* iterate through possible rhs parses, spawn fnction to check prefixes against this rhs *)
(* also derives nonterminals to terminals - downward movement *)
(* initializes both to recursive functions *)
let rec matcher start_sym rules rhs_list acceptor derivation frag =
    match rhs_list with
    [] -> None          (* none of the rhs rules returned well *)
    | rhs::tail_rhs_list ->
        match (match_rhs rules rhs acceptor (derivation@[start_sym, rhs]) frag) with
        None -> matcher start_sym rules tail_rhs_list acceptor derivation frag      (* check the next rhs *)
        |Some value -> Some value

(* check prefixes against rhs - rightward movement *)
(* curries matcher with matcher for next element *)
    and match_rhs rules rhs acceptor derivation frag (* args[] *) =
    match rhs with
    [] -> acceptor derivation frag  (* completed derivation of entire rhs, check to see if acceptable *)
    | rhs_sym::tail_rhs ->
        match frag with
        [] -> None                  (* fragment ended before rhs could finish: not valid *)
        | term_sym::tail_frag -> 
            match rhs_sym with
            T term -> if term = term_sym then (match_rhs rules tail_rhs acceptor derivation tail_frag) (* continue processing *) else None
            | N nonterm -> 
            let curried_acceptor = match_rhs rules rhs acceptor
            in
            matcher nonterm rules (rules nonterm) curried_acceptor derivation frag   (* curries matcher with matcher *)

    ;;


(* code to match terminals
T rhs -> matcher start_sym rules tail_rhs_list acceptor derivation@[] frag      (* process the terminal string *)
| N rhs ->                               (* process a nonterminal string *)
*)

(* parse prefix solution *)
let parse_prefix gram acceptor fragment =
    (* make generic matcher func *)
    (* curry the matcher for specific terminals *)
    (* append matchers required for this fragment to create big matcher *)
    (* return big matcher *)
    

    let start_sym = fst gram
    in
    let rules = snd gram 
    in
    let start_production = rules start_sym 
    in

    matcher start_sym rules start_production acceptor [] fragment
    ;;