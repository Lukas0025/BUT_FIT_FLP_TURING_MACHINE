#!/usr/bin/swipl

/**
 * Write string to stdout and put new line on end of string
 * @param [in] Str text to print
 */
writeLn(Str) :- write(Str), nl.

empty.
blank.

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
codes2chars(end_of_file, empty) :- !.
codes2chars([HC|TC], [H|T]) :- atom_codes(H, [HC]), codes2chars(TC, T).
codes2chars([], []).

/**
 * Convert stream of lines to array of lines
 * @param [in]  Stream stream with lines
 * @param [out] Lines array of lines in stream
 */
getLines(Stream, Lines) :- getLine(Stream, Line), (Line == empty -> Lines = [] ; Lines = [Line | T], getLines(Stream, T)).

/**
 * Parse one line of input
 */
paraseLines([Tape],    Tape).
paraseLines([],           _) :- fail.
paraseLines([Rule|T],  Tape) :- parseRule(Rule), paraseLines(T, Tape).

/**
 */
parseRule([CurState, ' ', CurChar, ' ', NewState, ' ', NewChar | _]) :- assert(rule(CurState, CurChar, NewState, NewChar)), !.
parseRule(Rule) :- write('Unsuported rule format '), writeLn(Rule).

/**
 */
replace(0, Replacement, [], [Replacement]).
replace(0, Replacement, [_|TOld], [Replacement|TOld]).
replace(Index, Replacement, [], [' '|TNew]) :- Index > 0, NewIndex is Index - 1, replace(NewIndex, Replacement, [], TNew).
replace(Index, Replacement, [H|TOld], [H|TNew]) :- NewIndex is Index - 1, replace(NewIndex, Replacement, TOld, TNew).

/**
 */
nth0Blank(_,     []   ,  ' ').
nth0Blank(0,     [H|_],    H).
nth0Blank(Index, [_|T], Item) :- NewIndex is Index - 1, nth0Blank(NewIndex, T, Item).

/**
 */
setConfiguration([], State, HeadPos, [' '|TC]) :- 0 < HeadPos, NewHeadPos is HeadPos - 1, setConfiguration([], State, NewHeadPos, TC).
setConfiguration([], State, 0      , [State]).
setConfiguration([], _, _, []).
setConfiguration([HT|TT], State, HeadPos, [HT|TC]) :-  HeadPos =\= 0, NewHeadPos is HeadPos - 1, setConfiguration(TT, State, NewHeadPos, TC).
setConfiguration(Tape, State, HeadPos, [State|TC]) :-  HeadPos == 0, NewHeadPos is HeadPos - 1, setConfiguration(Tape, State, NewHeadPos, TC).

/**
 */
printConfigurations([]).
printConfigurations([H|T]) :- printArray(H), nl, printConfigurations(T).

/**
 */
printArray([]).
printArray([H|T]) :- write(H), printArray(T).

/**
 */
%stepsTM(Tape, HeadPos, State, Configurations, Limit).
stepsTM(_, -1, _,  _, _)  :- !, fail.
stepsTM(_, _,  _,  _, 0)  :- !, fail.
stepsTM(Tape, HeadPos, 'F', [Conf], _) :- setConfiguration(Tape, 'F', HeadPos, Conf).
stepsTM(Tape, HeadPos, State, [Conf|T], Limit) :- 
    NewLimit is Limit - 1,
    nth0Blank(HeadPos, Tape, CurChar),
    rule(State, CurChar, NewState, NewChar),
    setConfiguration(Tape, State, HeadPos, Conf),
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


runTM(Tape, Configurations) :- stepsTM(Tape, 0, 'S', Configurations, 1000).

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

:- initialization(main).

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