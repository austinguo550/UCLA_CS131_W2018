:- use_module(library(clpfd)).

% kenken is essentially
%   length(T, N),
%   maplist(checkLength(N), T),
%   maplist(setDomain(N), T),           % choose elements from this range
%   maplist(constraints(T), C),         % make sure that constraints are held on this current solution 2d list
%   maplist(find_all_different, T),     % is to check that columns have no repeats
%   transpose(T, T_transpose),             % flip so we can check rows have no repeats
%   maplist(find_all_different, T_transpose),    % is to check that rows have no repeats
%   maplist(find_labeling, T).


%%% ==========================================================================================================

% Kenken using finite domain solver
% used for inspiration:
% http://programmablelife.blogspot.com/2012/07/prolog-sudoku-solver-explained.html

%%% ==========================================================================================================

% curried predicate: needed to be able to create curried function taking N applied on Rows
create_rows(N, Row) :- length(Row, N).  % http://www.swi-prolog.org/pldoc/man?predicate=length/2

% shapify - create NxN 2D matrix
shapify(N, T) :-    length(T, N), 
                    maplist(create_rows(N), T). % http://www.swi-prolog.org/pldoc/man?predicate=maplist/2

% Source http://blog.ivank.net/prolog-matrices.html
% trans(+M1, -M2) - transpose of square matrix
% 1. I get first column from Tail and make a first row (NT) from it
% 2. I transpose "smaller matrix" Rest into NRest
% 3. I take T and make it to be a first column of NTail
trans([[H|T] |Tail], [[H|NT] |NTail]) :- 
	firstCol(Tail, NT, Rest), trans(Rest, NRest), firstCol(NTail, T, NRest).
trans([], []).
% firstCol(+Matrix, -Column, -Rest)  or  (-Matrix, +Column, +Rest)
firstCol([[H|T] |Tail], [H|Col], [T|Rows]) :- firstCol(Tail, Col, Rows).
firstCol([], [], []).

% curried predicate to restrict populated elements to a be [1, N]
restrict_domain(N, Row) :- fd_domain(Row, 1, N).    % http://www.gprolog.org/manual/gprolog.html#sec307

% populate the NxN 2D matrix with elements that are within domain range using fd solver
populate(N, T, Ts) :-   maplist(restrict_domain(N), T), % constrain the var Row (domain) to values [1,N]
                        maplist(fd_all_different, T),   % make sure rows are distinct, removes currently mapped row's value from other rows' domains    % http://www.gprolog.org/manual/html_node/gprolog062.html#sec325
                        maplist(fd_all_different, Ts),  % make sure columns are distinct ... ""
                        maplist(fd_labeling, T).       % assigns values to row lists in T   % http://www.gprolog.org/manual/html_node/gprolog063.html


% Source https://stackoverflow.com/questions/7912783/prolog-getting-element-from-a-list-of-lists
decompose_components(X_comp-Y_comp, [X_comp, Y_comp]).

get_value(T, Point, Value) :- decompose_components(Point, [I, J]), nth1(I, T, Row), nth1(J, Row, Value). % http://www.swi-prolog.org/pldoc/man?predicate=nth1/3



apply_constraints(T, C) :- maplist(map_constraints(T), C).

%% curried constraint predicates

% apply numeric cage constraints
map_constraints(T, +(S, L)) :- check_sum(T, L, S).
map_constraints(T, *(P, L)) :- check_product(T, L, P).
map_constraints(T, -(D, J, K)) :- check_difference(T, J, K, D).
map_constraints(T, /(Q, J, K)) :- check_quotient(T, J, K, Q).

% sum constraint
check_sum(_, [], 0).        % if no more points to subtract, points in L meet the sum constraint if S = 0
check_sum(T, [Point1 | Points], S) :- get_value(T, Point1, Value), check_sum(T, Points, Accum), Accum #= S - Value.     % subtract value from sum

% product constraint
check_product(_, [], 1).    % if no more points to divide, points in L meet product constraint if P = 1
check_product(T, [Point | Points], P) :- get_value(T, Point, Value), check_product(T, Points, Accum), Accum #= P/Value. % divide matrix entry from product

% difference constraint
check_difference(T, J, K, D) :- get_value(T, J, J_val), get_value(T, K, K_val), D is J_val - K_val.
check_difference(T, J, K, D) :- get_value(T, K, K_val), get_value(T, J, J_val), D is K_val - J_val.

% quotient constraint
check_quotient(T, J, K, Q) :- get_value(T, J, J_val), get_value(T, K, K_val), Q is J_val / K_val, 0 is mod(J_val, K_val).
check_quotient(T, J, K, Q) :- get_value(T, J, J_val), get_value(T, K, K_val), Q is K_val / J_val, 0 is mod(K_val, J_val).


%% kenken function

kenken(N, C, T) :-  shapify(N, T), % create unpopulated NxN matrix
                    trans(T, Ts), % create transform of matrix
                    apply_constraints(T, C), % apply constraints to matrix
                    populate(N, T, Ts). % populate matrix and transposed matrix






%%% ==========================================================================================================

% Kenken without finite domain solver

%%% ==========================================================================================================

form_domain(N, []) :- form_domain(N-1, ).
form_domain(N, D) :- .

plain_shapify(N, T) :- member().


plain_kenken(N, C, T) :- plain_shapify(N, T).