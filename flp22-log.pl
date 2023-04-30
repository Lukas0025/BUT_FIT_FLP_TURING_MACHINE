#!/usr/bin/swipl

/**
 * @autor Lukáš Plevač <xpleva07@vutbr.cz>
 * @date 2023-04-30
 * Non deterministic turing machine implementation in prolog
 */ 

:- dynamic configuration/4.
:- dynamic rule/3.

/**
 * Write string to stdout and put new line on end of string
 * @param [in] Str text to print
 */
writeLn(Str) :- write(Str), nl.

/** 
 * Axiom representing EOF as empty line
 */
empty.

/**
 * Get one line from string as char array
 * @param [in]  Stream stream to get line
 * @param [out] Line   readed char array of line
 */
getLine(Stream, Line) :- read_line_to_codes(Stream, CodesLine), codes2chars(CodesLine, Line).

/**
 * Convert file line array of codes to array of chars
 * @param [inout] CodesLine array of codes
 * @param [inout] CharLine  array of chars (Atoms)
 */
codes2chars(end_of_file, empty).
codes2chars([HC|TC], [H|T]) :- atom_codes(H, [HC]), codes2chars(TC, T).
codes2chars([], []).

/**
 * Convert stream of lines to array of lines
 * @param [in]  Stream stream with lines
 * @param [out] Lines array of lines in stream
 */
getLines(Stream, Lines) :- getLine(Stream, Line), (Line == empty -> Lines = [] ; Lines = [Line | T], getLines(Stream, T)).

/**
 * Parse lines of input files run parsrule on rulse and last line use as Tape
 * @param [in] Lines Array of arrays of lines
 * @param [out] Tape array of chars of init tape 
 */
paraseLines([Tape],    Tape).
paraseLines([],           _) :- fail.
paraseLines([Rule|T],  Tape) :- parseRule(Rule), paraseLines(T, Tape).

/**
 * Parse rule and save it do prolog axiom database
 * @param [in] Rule Array of chars of rule in format [S, ' ', C, ' ', S, ' ', C] 
 */
parseRule([CurState, ' ', CurChar, ' ', NewState, ' ', NewChar | _]) :- assert(rule(CurState, CurChar, NewState, NewChar)).
parseRule(Rule) :- write('Unsuported rule format '), printArray(Rule), nl, halt(1).

/**
 * Replace or Insert item on Index in array if item is saperated of others put blacks in space between its
 * @param [in]  Index index of item to change
 * @param [in]  Replacemant new value of item
 * @param [in]  Old array with old value of item or without it if insert
 * @param [out] New array with new value of item
 */
replace(0, Replacement, [], [Replacement]).
replace(0, Replacement, [_|TOld], [Replacement|TOld]).
replace(Index, Replacement, [], [' '|TNew]) :- Index > 0, NewIndex is Index - 1, replace(NewIndex, Replacement, [], TNew).
replace(Index, Replacement, [H|TOld], [H|TNew]) :- NewIndex is Index - 1, replace(NewIndex, Replacement, TOld, TNew).

/**
 * Get element on index from array if not in array return blank symbol
 * @param [in]  Index index of element
 * @param [in]  Array array with element
 * @param [out] Item item from array on index
 */

nth0Blank(0,     [H|_],    H) :- !.
nth0Blank(_,     []   ,  ' ').
nth0Blank(Index, [_|T], Item) :- NewIndex is Index - 1, nth0Blank(NewIndex, T, Item).

/**
 * Set configuration to Configuration array
 * @param [in] Tape Tape of configuration
 * @param [in] State state of configuration
 * @param [in] HeadPos head position of configuration
 * @param [out] Configuration array of configuration (array of chars)
 */
setConfiguration([], State, HeadPos, [' '|TC]) :- 0 < HeadPos, NewHeadPos is HeadPos - 1, setConfiguration([], State, NewHeadPos, TC).
setConfiguration([], State, 0      , [State]).
setConfiguration([], _, _, []).
setConfiguration([HT|TT], State, HeadPos, [HT|TC]) :-  HeadPos =\= 0, NewHeadPos is HeadPos - 1, setConfiguration(TT, State, NewHeadPos, TC).
setConfiguration(Tape, State, HeadPos, [State|TC]) :-  HeadPos == 0, NewHeadPos is HeadPos - 1, setConfiguration(Tape, State, NewHeadPos, TC).

/**
 * Print configuration on stdout every one configuration to one line
 * @param [in] Configurations configurations to print
 */
printConfigurations([]).
printConfigurations([H|T]) :- printArray(H), nl, printConfigurations(T).

/**
 * Print array to std out items is on one line
 * @pram [in] array array to print
 */
printArray([]).
printArray([H|T]) :- write(H), printArray(T).

/**
 * Perform N steps with turing machine
 * @param [in] Tape              tape of turing machine
 * @param [in] HeadPos           Position of head of TM
 * @param [in] State             State of TM
 * @param [out] Configurations   configuratinons of TM to goal
 * @param [in]  Limit            maximal number of steps of TM
 */
stepsTM(_, -1, _,  _, Depth)  :- retract(configuration(_, _, _, Depth)), !, fail.
stepsTM(_, _,  _,  _, 0)      :- retract(configuration(_, _, _, 0)),     !, fail.
stepsTM(Tape, HeadPos, State, _, Depth)  :- configuration(Tape, State, HeadPos, _), retract(configuration(_, _, _, Depth)), !, fail. % this configuration is not new in Configurations skip it 
stepsTM(Tape, HeadPos, 'F', [Conf], _)   :- setConfiguration(Tape, 'F', HeadPos, Conf).
stepsTM(Tape, HeadPos, State, [Conf|T], Limit) :- 
    NewLimit is Limit - 1,
    nth0Blank(HeadPos, Tape, CurChar),
    rule(State, CurChar, NewState, NewChar),
    setConfiguration(Tape, State, HeadPos, Conf),
    assert(configuration(Tape, State, HeadPos, NewLimit)), %for optimalize back tracing
    (NewChar == 'L' -> (
        NewHeadPos is HeadPos - 1,
        stepsTM(Tape, NewHeadPos, NewState, T, NewLimit)
    ) ; (
        (NewChar == 'R' -> (
            NewHeadPos is HeadPos + 1,
            stepsTM(Tape, NewHeadPos, NewState, T, NewLimit) 
        ) ; (
            replace(HeadPos, NewChar, Tape, NewTape),
            stepsTM(NewTape, HeadPos, NewState, T, NewLimit)
        )
    ))).

stepsTM(_, _, _, _, Depth) :- retract(configuration(_, _, _, Depth)), fail. % retract last configuration before back tracing


/**
 * Run NON-DETERMINISTIC turing machine using DLS cearch method
 * @param [in] Tape input tape for TM
 * @param [out] Configuration configuratinons of TM to goal
 */
runTM(Tape, Configurations) :- runTMDLS(Tape, Configurations, 2, 1000000).


/**
 * Use DLS search method to prefer shorthest outputs every iteration depth icrese in power of 10 if curLim > 100 else its do tiny +1 setps incrise
 * @param [in]  Tape tape for turing machine
 * @param [out] Configurations configuratinons of TM to goal
 * @param [in]  CurLim current limit of steps
 * @param [in]  Limit global maximal limit of number of steps of TM (To prevent cycles)
 */
runTMDLS(Tape, Configurations, CurLim, _)     :- stepsTM(Tape, 0, 'S', Configurations, CurLim).
runTMDLS(Tape, Configurations, CurLim, Limit) :- (CurLim < 100, NewLimit is CurLim + 1 ; NewLimit is CurLim * 10), NewLimit =< Limit, runTMDLS(Tape, Configurations, NewLimit, Limit).
runTMDLS(_, _, CurLim, _)                     :- write("TM Abnormal stop or cycle detect used upto "), write(CurLim), writeLn(" steps"), halt(1).

/**
 * Get transition rules and inital tape from file and save rules to prolog database
 * @param [in]  FileName file name of file with init configuration of turing machine
 * @param [out] inital tape for turing machine
 */
loadFile(File, Tape) :-
    open(File, read, Stream),
    getLines(Stream, Lines),
    paraseLines(Lines, Tape),
    close(Stream).

% if using as interpreth
%:- initialization(main).

main :-
    current_prolog_flag(argv, Argv),
    length(Argv, Argc),
    
    (Argc < 1 -> writeLn('No input file present') ; 
        nth0(0, Argv, FileName), % get first argument
        loadFile(FileName, Tape),
        runTM(Tape, Configurations),
        printConfigurations(Configurations)
    ),

    halt.