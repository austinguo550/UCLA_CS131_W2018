(* convert grammar: grammar2 is start_sym, production for each nonterminal given matching function *)
let rec build_productions nonterm grammar =
    match grammar with
    [] -> []
    | (curr_nonterm, rhs)::t -> if curr_nonterm = nonterm then rhs::(build_productions nonterm t) else (build_productions nonterm t)
    ;;
(* val build_productions : 'a -> ('a * 'b) list -> 'b list = <fun> *)

let convert_grammar gram1 =
    ((fst gram1), fun nonterm -> build_productions nonterm (snd gram1))
    ;;
(* val convert_grammar : 'a * ('b * 'c) list -> 'a * ('b -> 'c list) = <fun> *)


type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal
(* type ('nonterminal, 'terminal) symbol = N of 'nonterminal | T of 'terminal *)



(* iterate through possible rhs parses, spawn fnction to check prefixes against this rhs *)
(* also derives nonterminals to terminals - downward movement *)
(* initializes both to recursive functions *)
let rec matcher start_sym rules rhs_list accept derivation frag =
    match rhs_list with
    [] -> None          (* none of the rhs rules returned well *)
    | rhs::tail_rhs_list ->
        match (match_rhs rules rhs accept (derivation@[start_sym, rhs]) frag) with
        None -> matcher start_sym rules tail_rhs_list accept derivation frag      (* check the next rhs *)
        |Some value -> Some value
(* val matcher :
  'a ->
  ('a -> ('a, 'b) symbol list list) ->
  ('a, 'b) symbol list list ->
  (('a * ('a, 'b) symbol list) list -> 'b list -> 'c option) ->
  ('a * ('a, 'b) symbol list) list -> 'b list -> 'c option = <fun> *)



(* check prefixes against rhs - rightward movement *)
(* curries matcher with matcher for next element *)
    and match_rhs rules rhs accept derivation frag =
    match rhs with
    [] -> accept derivation frag  (* completed derivation of entire rhs, check to see if acceptable *)
    | rhs_sym::tail_rhs ->
        match frag with
        [] -> None                  (* fragment ended before rhs could finish: not valid *)
        | term_sym::tail_frag -> 
            match rhs_sym with
            T term -> if term = term_sym then (match_rhs rules tail_rhs accept derivation tail_frag) (* continue processing *) else None
            | N nonterm -> 
            let curried_accept = match_rhs rules tail_rhs accept
            in
            matcher nonterm rules (rules nonterm) curried_accept derivation frag   (* curries matcher with matcher *)
    ;;
(* val match_rhs :
  ('a -> ('a, 'b) symbol list list) ->
  ('a, 'b) symbol list ->
  (('a * ('a, 'b) symbol list) list -> 'b list -> 'c option) ->
  ('a * ('a, 'b) symbol list) list -> 'b list -> 'c option = <fun> *)




(* code to match terminals
T rhs -> matcher start_sym rules tail_rhs_list acceptor derivation@[] frag      (* process the terminal string *)
| N rhs ->                               (* process a nonterminal string *)
*)

(* parse prefix solution *)
let parse_prefix gram accept frag =
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

    matcher start_sym rules start_production accept [] frag
    ;;
(* val parse_prefix :
  'a * ('a -> ('a, 'b) symbol list list) ->
  (('a * ('a, 'b) symbol list) list -> 'b list -> 'c option) ->
  'b list -> 'c option = <fun> *)