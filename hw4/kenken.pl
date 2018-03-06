% Kenken using finite domain solver
% used for inspiration:
% http://programmablelife.blogspot.com/2012/07/prolog-sudoku-solver-explained.html
% maplist used to apply curried functions quickly to entire list without explicitly writing out iterations

%%%%% Helper functions

% shapify - create NxN 2D matrix
shapify(N, T) :-    length(T, N), 
                    create_columns(N, T).

create_columns(N, []). % when there are no more rows to create columns for
create_columns(N, [H|T]) :- length(H, N), create_columns(N, T). % create columns for each row

% when taking the transpose the objects will still be the same blocks of memory, so mapping fd domains and 
  % distinct elements on each part will be saved across T and Ts
% can either take the matrix and return a column and tail, or take in latter 2 and return matrix
first_column([], [], []).   % base case
first_column([[H|T] |Tail], [H|Col], [T|Rows]) :- first_column(Tail, Col, Rows).
% First retrieve first column from tail and set it to first row of NT while retrieving Rest matrix
% Transpose Rest to NRest and use NRest and the tail T of the first row to populate NTail matrix
trans([], []).    % no more rows and columns to transpose
trans([ [H|T] | Tail ], [ [H|NT] | NTail ]) :- first_column(Tail, NT, Rest), trans(Rest, NRest), first_column(NTail, T, NRest).


restrict_domain([], N). % no more elements to restrict domain for
restrict_domain([Row|T], N) :- fd_domain(Row, 1, N), restrict_domain(T, N). % restrict domain for current row


get_value(T, [I|J], Value) :- nth1(I, T, Row), nth1(J, Row, Value).  % get the jth element of the ith row


% use maplist because faster, cleaner mapping of fd_all_different and piazza mentions will work better
fill_with_different(T, Ts) :-   maplist(fd_all_different, T),   % make sure rows are distinct, removes currently mapped row's value from other rows' domains 
                                maplist(fd_all_different, Ts).  % make sure columns are distinct ... ""


% make sure it is true that list elements can add/multiply/subtract/divide and = result given
apply_constraints(T, C) :- maplist(curried_constraint(T), C).

%% curried constraint predicates

% apply numeric cage constraints to each element in the list of constraints using pattern matching
curried_constraint(T, +(S, L)) :- check_sum(T, L, S, 0).
curried_constraint(T, *(P, L)) :- check_product(T, L, P, 1).
curried_constraint(T, -(D, J, K)) :- check_difference(T, J, K, D).
curried_constraint(T, /(Q, J, K)) :- check_quotient(T, J, K, Q).

% TA mentioned need to use #= to account for fd vars manipulation instead of =:= or is (matrix elements are fd vars)
% sum constraint
check_sum(_, [], S, S). % recursive base case: compare the sum with the accumulated sum
check_sum(T, [Point|Other_points], S, Accum) :- get_value(T, Point, Value), Sum #= Accum + Value, check_sum(T, Other_points, S, Sum).

% product constraint
check_product(_, [], P, P). % recursive base case: compare the product with the accumulated product
check_product(T, [Point|Other_points], P, Accum) :- get_value(T, Point, Value), Product #= Accum * Value, check_product(T, Other_points, P, Product).

% difference constraint
check_difference(T, J, K, D) :- get_value(T, J, J_val), get_value(T, K, K_val), Diff #= J_val - K_val, D = Diff. %compare_values(D, Diff). .
check_difference(T, J, K, D) :- get_value(T, K, K_val), get_value(T, J, J_val), Diff #= K_val - J_val, D = Diff. %compare_values(D, Diff). %D == Diff.

% quotient constraint
check_quotient(T, J, K, Q) :- get_value(T, J, J_val), get_value(T, K, K_val), Quotient #= J_val / K_val, Q = Quotient.
check_quotient(T, J, K, Q) :- get_value(T, J, J_val), get_value(T, K, K_val), Quotient #= K_val / J_val, Q = Quotient.


% populate the NxN 2D matrix with fd vars that are within domain range using fd solver
populate(N, C, T, Ts) :-    restrict_domain(T, N),          % constrain the Row vars (domain) to values [1,N]
                            fill_with_different(T, Ts),     % make sure the rows and columns have distinct values within domain
                            apply_constraints(T, C),        % apply constraints to matrix
                            maplist(fd_labeling, T).        % assigns final values to row lists in T



%% kenken function
% similar to sudoku, need to generate empty matrix, get transpose of same matrix in memory, populatee it with distinct elements in fd label
% extra part is applying extra constraints instead of adding blocks
kenken(N, C, T) :-  shapify(N, T),              % create unpopulated NxN matrix
                    trans(T, Ts),               % create transform of matrix
                    populate(N, C, T, Ts).      % populate matrix and transposed matrix with constraints and domain




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Kenken without finite domain solver
% instead use member/2 (which tells if an element X is in list []), is/2

form_domain(N, D) :- findall(X, between(1, N, X), D). % populates domain with vars X such that X is in range [1,N]

non_fd_all_different(D, []).
non_fd_all_different(D, [H|T]) :- member(H, D), non_fd_all_different(D, T), \+member(H, T).   % make sure each row element is in domain and not in rest of row


plain_fill_with_different(D, T, Ts) :-  maplist(non_fd_all_different(D), T),    % make sure rows have different elements
                                        maplist(non_fd_all_different(D), Ts).   % make sure columns have different elements


apply_plain_constraints(T, C) :- maplist(plain_curried_constraint(T), C).     % apply plain curried constraints

%% curried constraint predicates for plain kenken (is used instead of #=, according to TA since #= used for fd solver vars only)

% apply numeric cage constraints to each element in the list of constraints using pattern matching
plain_curried_constraint(T, +(S, L)) :- plain_check_sum(T, L, S, 0).
plain_curried_constraint(T, *(P, L)) :- plain_check_product(T, L, P, 1).
plain_curried_constraint(T, -(D, J, K)) :- plain_check_difference(T, J, K, D).
plain_curried_constraint(T, /(Q, J, K)) :- plain_check_quotient(T, J, K, Q).

% sum constraint
plain_check_sum(_, [], S, S). % recursive base case: compare the sum with the accumulated sum
plain_check_sum(T, [Point|Other_points], S, Accum) :- get_value(T, Point, Value), Sum is Accum + Value, check_sum(T, Other_points, S, Sum).

% product constraint
plain_check_product(_, [], P, P). % recursive base case: compare the product with the accumulated product
plain_check_product(T, [Point|Other_points], P, Accum) :- get_value(T, Point, Value), Product is Accum * Value, check_product(T, Other_points, P, Product).

% difference constraint
plain_check_difference(T, J, K, D) :- get_value(T, J, J_val), get_value(T, K, K_val), Diff is J_val - K_val, D = Diff. %compare_values(D, Diff). .
plain_check_difference(T, J, K, D) :- get_value(T, K, K_val), get_value(T, J, J_val), Diff is K_val - J_val, D = Diff. %compare_values(D, Diff). %D == Diff.

% quotient constraint
plain_check_quotient(T, J, K, Q) :- get_value(T, J, J_val), get_value(T, K, K_val), Quotient is J_val / K_val, Q = Quotient.
plain_check_quotient(T, J, K, Q) :- get_value(T, J, J_val), get_value(T, K, K_val), Quotient is K_val / J_val, Q = Quotient.


plain_populate(N, C, T, Ts) :-  form_domain(N, D),  % elements of T must be part of domain D
                                plain_fill_with_different(D, T, Ts),
                                apply_plain_constraints(T, C).  % apply constraints


plain_kenken(N, C, T) :-    shapify(N, T),
                            trans(T, Ts),
                            plain_populate(N, C, T, Ts).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% No-op kenken is in the file noopkenken.txt
% Has no implementation: only contains API and example call

kenken_testcase(
    6,
    [
     +(11, [[1|1], [2|1]]),
     /(2, [1|2], [1|3]),
     *(20, [[1|4], [2|4]]),
     *(6, [[1|5], [1|6], [2|6], [3|6]]),
     -(3, [2|2], [2|3]),
     /(3, [2|5], [3|5]),
     *(240, [[3|1], [3|2], [4|1], [4|2]]),
     *(6, [[3|3], [3|4]]),
     *(6, [[4|3], [5|3]]),
     +(7, [[4|4], [5|4], [5|5]]),
     *(30, [[4|5], [4|6]]),
     *(6, [[5|1], [5|2]]),
     +(9, [[5|6], [6|6]]),
     +(8, [[6|1], [6|2], [6|3]]),
     /(2, [6|4], [6|5])
    ]
  ).


no_op_kenken_testcase(
    3,
    [
      *(6, [[1|2], [2|1]]),
      +(2, [[2|2], [3|3]]),
      +(3, [[1|1], [1|3]])
    ]
  ).

kenken(
  4,
  [
   +(6, [[1|1], [1|2], [2|1]]),
   *(96, [[1|3], [1|4], [2|2], [2|3], [2|4]]),
   -(1, [3|1], [3|2]),
   -(1, [4|1], [4|2]),
   +(8, [[3|3], [4|3], [4|4]]),
   *(2, [[3|4]])
  ],
  T
), write(T), nl, fail.