(* Grammar definition *)
type my_nonterminals = 
  | Exp | Intro | Prefix | Slang | Noun | Greeting

let my_grammar =
  (Exp,
   function
     | Exp ->
         [[N Intro; N Noun; N Exp];
          [N Intro]]
     | Intro ->
	 [[N Greeting];
	  [N Prefix];
	  [N Slang; N Prefix];
	  [N Prefix; N Slang];
	  [T"("; N Exp; T")"]]
     | Prefix ->
	 [[T"$"; N Exp]]
     | Slang ->
	 [[T"there"];
	  [T"partner"]]
     | Noun ->
	 [[T"Google"];
	  [T"World"]]
     | Greeting ->
	 [[T"Hi"]; [T"Hey"]; [T"What's up"]; [T"Wack"]; [T"Yo"];
	  [T"Sup"]; [T"Howdy"]; [T"Welcome"]; [T"Hello"]; [T"Ni hao"]])



(* Acceptors *)
let accept_all derivation string = Some (derivation, string)

let rec has_greeting =
    function
    [] -> false
    | (Greeting, _)::t -> true
    | _::t -> has_greeting t
let accept_greetings derivation string =
    if has_greeting derivation then Some(derivation, string) else None



(* Tests *)
let test_1 =
 (parse_prefix my_grammar accept_all
     ["("; "$"; "Hello"; ")"; "World"; "$"; "there"; "$"; "partner"; "$"; "Ni hao"; "Google";
      "("; "$"; "there"; "$"; "What's up"; "Google"; "("; "Hello"; ")"; "World"; "Ni hao"; ")";
      "World"; "("; "$"; "$"; "$"; "$"; "$"; "there"; "$"; "$"; "Sup"; "there";
      "there"; "partner"; ")"; "World"; "there"; "$"; "$"; "("; "$"; "Hello"; "there"; ")";
      "there"; "Google"; "Hi"])
  = Some
     ([(Exp, [N Intro; N Noun; N Exp]); (Intro, [T "("; N Exp; T ")"]);
       (Exp, [N Intro]); (Intro, [N Prefix]); (Prefix, [T "$"; N Exp]);
       (Exp, [N Intro]); (Intro, [N Greeting]); (Greeting, [T "Hello"]); (Noun, [T "World"]);
       (Exp, [N Intro; N Noun; N Exp]); (Intro, [N Prefix]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro; N Noun; N Exp]);
       (Intro, [N Slang; N Prefix]); (Slang, [T "there"]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro; N Noun; N Exp]);
       (Intro, [N Slang; N Prefix]); (Slang, [T "partner"]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro; N Noun; N Exp]);
       (Intro, [N Greeting]); (Greeting, [T "Ni hao"]); (Noun, [T "Google"]); (Exp, [N Intro]);
       (Intro, [T "("; N Exp; T ")"]); (Exp, [N Intro; N Noun; N Exp]);
       (Intro, [N Prefix]); (Prefix, [T "$"; N Exp]);
       (Exp, [N Intro; N Noun; N Exp]); (Intro, [N Slang; N Prefix]);
       (Slang, [T "there"]); (Prefix, [T "$"; N Exp]); (Exp, [N Intro]);
       (Intro, [N Greeting]); (Greeting, [T "What's up"]); (Noun, [T "Google"]); (Exp, [N Intro]);
       (Intro, [T "("; N Exp; T ")"]); (Exp, [N Intro]); (Intro, [N Greeting]);
       (Greeting, [T "Hello"]); (Noun, [T "World"]); (Exp, [N Intro]); (Intro, [N Greeting]);
       (Greeting, [T "Ni hao"]); (Noun, [T "World"]); (Exp, [N Intro]);
       (Intro, [T "("; N Exp; T ")"]); (Exp, [N Intro]); (Intro, [N Prefix]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro]); (Intro, [N Prefix]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro]); (Intro, [N Prefix]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro]); (Intro, [N Prefix; N Slang]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro]); (Intro, [N Prefix; N Slang]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro]); (Intro, [N Slang; N Prefix]);
       (Slang, [T "there"]); (Prefix, [T "$"; N Exp]); (Exp, [N Intro]);
       (Intro, [N Prefix; N Slang]); (Prefix, [T "$"; N Exp]); (Exp, [N Intro]);
       (Intro, [N Greeting]); (Greeting, [T "Sup"]); (Slang, [T "there"]); (Slang, [T "there"]);
       (Slang, [T "partner"]); (Noun, [T "World"]); (Exp, [N Intro]);
       (Intro, [N Slang; N Prefix]); (Slang, [T "there"]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro]); (Intro, [N Prefix; N Slang]);
       (Prefix, [T "$"; N Exp]); (Exp, [N Intro]);
       (Intro, [T "("; N Exp; T ")"]); (Exp, [N Intro]);
       (Intro, [N Prefix; N Slang]); (Prefix, [T "$"; N Exp]); (Exp, [N Intro]);
       (Intro, [N Greeting]); (Greeting, [T "Hello"]); (Slang, [T "there"]); (Slang, [T "there"]);
       (Noun, [T "Google"]); (Exp, [N Intro]); (Intro, [N Greeting]); (Greeting, [T "Hi"])],
      [])


let test_2 = 
    (parse_prefix my_grammar accept_greetings ["$"; "partner"; "Google"; "world"]) = None
    ;;