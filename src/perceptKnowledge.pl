% Some information about the agent itself from the percepts
money(M) :- percept(money(M)).
energy(E) :- percept(energy(E)).
maxEnergyWorking(E) :- percept(maxEnergy(E)).
maxEnergyDisabled(E) :- percept(maxEnergyDisabled(E)).
strength(S) :- percept(strength(S)).
maxHealth(H) :- percept(maxHealth(H)).
visibilityRange(R) :- percept(visRange(R)).

% Visible entities, vertices and edges from the percepts
visibleEntity(Id,Vertex,Team,Status) :- percept(visibleEntity(Id,Vertex,Team,Status)).
visibleEdge(Vertex1,Vertex2) :- percept(visibleEdge(Vertex1,Vertex2)).
visibleEdge(Vertex1,Vertex2) :- percept(visibleEdge(Vertex2,Vertex1)).

% Round information from the percepts
lastAction(Action) :- percept(lastAction(Action)).
lastActionParam(Param) :- percept(lastActionParam(Param)).
lastActionResult(failed_parry) :- percept(lastActionResult(failed_parry)), !.
lastActionResult(failed_in_range) :- percept(lastActionResult(failed_in_range)), !.
lastActionResult(failed_attacked) :- percept(lastActionResult(failed_attacked)), !.
lastActionResult(Result) :- percept(lastActionResult(Result)).
lastActionResultFailed :- percept(lastActionResult(Result)), atom_chars(Result,Chrs), append([f,a,i,l,e,d],_,Chrs).
