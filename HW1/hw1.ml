(* 1 subset a b *)
let rec subset a b =
    match a with
    [] -> true
    | h::t -> if List.mem h b then subset t b else false
    ;;

(* 2 equal_sets a b *)
let equal_sets a b =
    if subset a b && subset b a then true else false ;;

(* 3 set_union a b *)
let rec set_union a b =
    match a with
    [] -> b
    | h::t -> if List.mem h b then set_union t b else set_union t (h::b)
    ;;

(* 4 set_intersection a b *)
let rec set_intersection a b =
    match a with
    [] -> []
    | h::t -> if List.mem h b then h::set_intersection t b else set_intersection t b
    ;;

(* 5 set_diff a b *)
let rec set_diff a b =
    match a with
    [] -> []
    | h::t -> if List.mem h b then set_diff t b else h::set_diff t b
    ;;

(* 6 computed_fixed_point eq f x *)
let rec computed_fixed_point eq f x =
    if eq (f x) x then x else computed_fixed_point eq f (f x)
    ;;

(* 7 computed_periodic_point eq f p x *)
let computed_periodic_point eq f p x = 
    let rec period_increase eq f p x value =
        match p with
        0 -> if eq x value then value else period_increase eq f p (f x) (f value)
        | _ -> period_increase eq f (p-1) (f x) value in
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
let filter_blind_alleys g =
    
    (fst g, set_intersection (computed_fixed_point (=) (create_terminal_rhs (snd g)) []) (snd g));;
    ;;
