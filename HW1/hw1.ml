(* 1 subset a b *)
let rec subset a b =
    match a with
    [] -> true
    | h::t -> if List.mem h b then subset t b else false
    ;;

(* 2 equal_sets a b *)
let equal_sets a b =
    subset a b && subset b a
    ;;

(* 3 set_union a b *)
let rec set_union a b =
    match a with
    [] -> b
    | h::t -> if List.mem h b then set_union t b else set_union t (h::b)
    ;;

(* 4 set_intersection a b *)
let set_intersection a b =
    List.filter (fun x -> List.mem x a) b
    ;;

(* 5 set_diff a b *)
let set_diff a b =
    List.filter (fun x -> not (List.mem x b)) a
    ;;

(* 6 computed_fixed_point eq f x *)
let rec computed_fixed_point eq f x =
    if eq (f x) x then x else computed_fixed_point eq f (f x)
    ;;

(* 7 computed_periodic_point eq f p x *)
(* recursive helper function to check the function value after a period of compositions *)
let rec period_increase eq f p x value =
    match p with
    0 -> if eq x value then value else period_increase eq f p (f x) (f value)
    | _ -> period_increase eq f (p-1) (f x) value
    ;;

let computed_periodic_point eq f p x = 
    period_increase eq f p x x
    ;;

(* 8 while_away s p x *)
let rec while_away s p x =
    if p x then x::while_away s p (s x) else []
    ;;

(* 9 rle_decode lp *)
let rec rle_decode lp =
    match lp with
    [] -> []
    | (n, el)::t -> if n = 0 then rle_decode t else el::rle_decode ((n-1, el)::t)
    ;;

(* define symbol *)
type ('nonterminal, 'terminal) symbol =
  | N of 'nonterminal
  | T of 'terminal

(* 10 filter_blind_alleys g *)

(* checks to see if the symbol should be added to the grammar *)
let isValid sym constructed_grammar =
    match sym with
    T sym -> true
    | N sym -> List.exists (fun x -> (fst x) = sym) constructed_grammar
    ;;

(* iterating through symbols in a right hand side to see which should be added to the grammar *)
let rec check_symbols current_rhs constructed_grammar =
    match current_rhs with
    [] -> true
    | sym::t -> if isValid sym constructed_grammar then true && (check_symbols t constructed_grammar) else false
    ;;

let rec build_grammar all_rules constructed_grammar =
    match all_rules with
    [] -> constructed_grammar
    | rule::t -> if (check_symbols (snd rule) constructed_grammar) && (not (subset [rule] constructed_grammar)) then build_grammar t (rule::constructed_grammar) else build_grammar t constructed_grammar
    ;;

let mask_valid_rules g l =
    set_intersection (computed_fixed_point (=) (build_grammar (snd g)) []) l
    ;;

(* build grammar from terminal symbols up, without blind alleys *)
let filter_blind_alleys g =
    (fst g, mask_valid_rules g (snd g))
    ;;