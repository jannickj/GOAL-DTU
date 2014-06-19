args_to_string([],'').
args_to_string([M],String):-atom_to_string(M,String),!.
atom_to_string(Tuple, String):-
	Tuple =..[Komma|Args],
	Komma = ',',
	args_to_string(Args,SArg),
	string_concat('(',SArg,SFunc2),
	string_concat(SFunc2, ')',String),!.
args_to_string([M|List], String):-
	atom_to_string(M,SM),
	args_to_string(List,SList),
	string_concat(SM,',',SM2),
	string_concat(SM2,SList,String).

atom_to_string(Atom, String):-Atom =..[String|[]],!.
atom_to_string(List, String):-
	is_list(List),
	args_to_string(List,SList),
	string_concat('[',SList,S1),
	string_concat(S1,']',String)
	,!.
atom_to_string(Atom, String):-
	Atom =..[Func|Args],
	string_concat(Func,'(',SFunc1),
	args_to_string(Args,SArg),
	string_concat(SFunc1,SArg,SFunc2),
	string_concat(SFunc2, ')',String).

logP([Text1,Text2|T]) :- 
	atom_to_string(Text1,SText1),
	atom_to_string(Text2,SText2),
	string_concat(SText1,SText2,Text),logP([Text|T]).
logP([Text]) :- me(AName),step(CurStep),
	atom_to_string(Text,SText),
	string_concat('debugging/',AName,FileName),
	open(FileName, append, Stream),
	get_time(Time),format_time(atom(FTime),'%Y-%m-%d %H:%M:%S:%3f',Time),
	string_concat(FTime,'(',FTime1),string_concat(FTime1,CurStep,FTime2),string_concat(FTime2,')  ',FTime3),
	%string_concat(FTime3, 'raw_time: ', Time2),
	%string_concat(Time2, Time, Time3),
	string_concat(FTime3,SText,TimeText),write(Stream,TimeText),nl(Stream),close(Stream).
