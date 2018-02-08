let my_subset_test0 = not (subset [3] [1;2])
let my_subset_test1 = subset [3] [1;3;3;3]

let my_equal_sets_test0 = equal_sets [1;2] [2;1]
let my_equal_sets_test1 = equal_sets [1] [1;1;1;1]
let my_equal_sets_test2 = equal_sets [] []

let my_set_union_test0 = equal_sets (set_union [1;2] [2;3]) [1;2;3]
let my_set_union_test1 = equal_sets (set_union [1;2] [4;5]) [1;2;4;5]
let my_set_union_test2 = not (equal_sets (set_union [1;2;3;4;5] [3;4]) [3;4])

let my_set_intersection_test0 = equal_sets (set_intersection [1;2;3;4;5] [3;4]) [3;4]
let my_set_intersection_test1 = equal_sets (set_intersection [] []) []
let my_set_intersection_test2 = equal_sets (set_intersection [] [1;3]) []
let my_set_intersection_test3 = not (equal_sets (set_intersection [1;2] [2;3]) [1;2;3])

let my_set_diff_test0 = equal_sets (set_diff [1;2;3;4;5] [4;5]) [1;2;3]
let my_set_diff_test1 = equal_sets (set_diff [1;3] []) [1;3]
let my_set_diff_test2 = equal_sets (set_diff [1;2;3;4;5] [1;2;3;4;5]) []
let my_set_diff_test3 = equal_sets (set_diff [] []) []
let my_set_diff_test4 = equal_sets (set_diff [] [1;2;3;4]) []

let my_computed_fixed_point_test0 = computed_fixed_point (=) (fun x -> x *. x) 1000000000. = infinity
let my_computed_fixed_point_test1 = computed_fixed_point (=) (fun x -> x * 1) 1000000000 = 1000000000

let my_computed_periodic_point_test0 = computed_periodic_point (=) (fun x -> x / 2) 0 (-1) = -1
let my_computed_periodic_point_test1 = computed_periodic_point (=) (fun x -> x / 2) 0 (2) = 2
let my_computed_periodic_point_test2 = computed_periodic_point (=) (fun x -> x * 2 - 2) 1 (2) = 2

let my_while_away_test0 = equal_sets (while_away (fun x -> x - 2) (fun y -> y > 0) 2) [2]
let my_while_away_test1 = equal_sets (while_away (fun x -> x - 2) (fun y -> y > 0) 10) [10;8;6;4;2]

let my_rle_decode_test0 = equal_sets (rle_decode [2,0; 1,6]) [0;0;6]
let my_rle_decode_test1 = equal_sets (rle_decode [0,0; 1,20]) [20]
let my_rle_decode_test2 = equal_sets (rle_decode [3,"w"; 1,"x"; 0,"y"; 2,"z"]) ["w"; "w"; "w"; "x"; "z"; "z"]

type example_grammar_nonterminals = Stmt | BadStmt | While | For | If | Block

let example_grammar = 
    Block,
    [Stmt, [T"a++;"];
    Block, [N While];
    Block, [N For];
    Block, [N If];
    Block, [N BadStmt];
    BadStmt, [N BadStmt];
    While, [T"while (a == b) "; N Stmt];
    For, [T"for (int a = 0; a < 3; a++) "; N Stmt];
    If, [T"if (a == 0) "; N Stmt]]

let my_filter_blind_alleys_test0 = filter_blind_alleys (example_grammar) = (Block,
   [(Stmt, [T "a++;"]); (Block, [N While]); (Block, [N For]);
    (Block, [N If]); (While, [T "while (a == b) "; N Stmt]);
    (For, [T "for (int a = 0; a < 3; a++) "; N Stmt]);
    (If, [T "if (a == 0) "; N Stmt])])