insertSorted(X, [], [X]).
insertSorted(X, [Y|Rest], [X,Y|Rest]) :-
    X @< Y, !.
insertSorted(X, [Y|Rest0], [Y|Rest]) :-
    insertSorted(X, Rest0, Rest).


updateFront(N,EF,NewEF,Heu):-
	N=node(Pos,_,SCost),
	\+ member((_,node(Pos,_,_)),EF),
	HeuCost is SCost + Heu,
	insertSorted((HeuCost,N),EF,NewEF).
updateFront(N,EF,NewEF,Heu):-
	N=node(Pos,_,SCost),
	append(StEF,[OtherNode|EndEF],EF),
	OtherNode = (_,node(Pos,_,OCost)),
	SCost < OCost,
	HeuCost is SCost + Heu,
	append(StEF,EndEF,TempEF),
	insertSorted((HeuCost,N),TempEF,NewEF).

updateExplored(N,EF,EF):-
	N=node(Pos,_,_),
	\+ member(node(Pos,_,_),EF).
updateExplored(N,EF,NewEF):-
	N=node(Pos,_,SCost),
	append(StEF,[OtherNode|EndEF],EF),
	OtherNode = (_,node(Pos,_,OCost)),
	SCost < OCost,
	append(StEF,EndEF,NewEF).

checkSuc([],F,F,E,E,_,_).
checkSuc(Successor, OldFrontier, NewFrontier, OldExplored, NewExplored,Goal,HeuFunc):-
	Successor = node(SPos,_,_),
	Goal = node(GPos,_,_),
	CalcHeu =..[HeuFunc,SPos,GPos,Heu],
	call(CalcHeu),
	updateExplored(Successor,OldExplored,NewExplored),
	updateFront(Successor,OldFrontier,NewFrontier,Heu).

asLoopSuc([],F,F,E,E,_,_).
asLoopSuc([Suc|Successors],OldFrontier, FinalFrontier, OldExplored, FinalExplored,Goal,HeuFunc):-
	(
	   checkSuc(Suc,OldFrontier, NewFrontier, OldExplored, NewExplored,Goal,HeuFunc),!;
	  (OldFrontier=NewFrontier,OldExplored=NewExplored)
	),
	asLoopSuc(Successors,NewFrontier,FinalFrontier, NewExplored, FinalExplored,Goal,HeuFunc).



aStarMainLoop(N,node(GPos,_,_),_,_,_,_,GoalFunc,_,_,N) :-
	N=node(CPos,_,_),CheckGoal =..[GoalFunc,CPos,GPos],call(CheckGoal),!.
aStarMainLoop(CurrentNode,GoalNode,Frontier,Explored,HeuFunc, AdjNodeFunc,GoalFunc, StartTime,MaxTime,EndNode) :-
	CurrentNode = node(CurrentPos, _, SCost),
	findall( AdjN,
		 ( FindAdjNode =.. [AdjNodeFunc, CurrentPos, (AdjCost,AdjPos)],
		   call(FindAdjNode),
		   AdjFullCost is AdjCost + SCost,
		   AdjN = node(AdjPos,CurrentNode, AdjFullCost)
		 ), L),
	asLoopSuc(L,Frontier,NewFrontier,Explored,TempExplored,GoalNode,HeuFunc),
	NewFrontier = [(_,NewCurrent)|RestFront],
	NewExplored = [CurrentNode|TempExplored],!,
	aStarMainLoop(NewCurrent,GoalNode,RestFront,NewExplored,HeuFunc,AdjNodeFunc,GoalFunc, StartTime,MaxTime,EndNode).
aStarMainLoop(_,_,[],_,_,_,_,_,_,_):-!,fail.


aStarGenRoute(nil,R,R).
aStarGenRoute(node(Pos,Parent,_),Route,FinalRoute):-
	aStarGenRoute(Parent,[Pos|Route],FinalRoute).

aStarSearch(StartPos,GoalPos,MaxTime,HeuFunc,AdjNodeFunc, GoalFunc,Route, Cost):-
	aStarMainLoop(node(StartPos,nil,0),node(GoalPos,_,_),[],[],HeuFunc,AdjNodeFunc, GoalFunc,CurTime,MaxTime,EndNode),!,
	EndNode=node(_, _,Cost),
	aStarGenRoute(EndNode,[],Route),!.
