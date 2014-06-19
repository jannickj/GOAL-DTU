% Energy/money checks
energyGE(Nr) :- Nr = unknown, energy(E), E >= 9.
energyGE(Nr) :- Nr \= unknown, energy(E), E >= Nr.
moneyGE(Nr) :- money(M), M >= Nr.
maxEnergy(E) :- disabled, maxEnergyDisabled(E), !.
maxEnergy(E) :- not(disabled), maxEnergyWorking(E).
recharge(Nr) :- not(disabled), maxEnergy(E), Nr is round(0.5*E).
recharge(Nr) :- disabled, maxEnergy(E), Nr is round(0.3*E).

% Energy cost of ranged actions
energyRangedGE(Base,V) :- currentPos(V), energyGE(Base), !.
energyRangedGE(Base,V) :- neighbour(V), N is Base+1, energyGE(N), !.
energyRangedGE(Base,V) :- not(currentPos(V)), not(neighbour(V)), currentPos(S), pathShortest(S,V,L,_), !, length(L,Dist), N is Base+Dist-1, energyGE(N).

% Role of the agent
role(Role) :- me(Id), role(Id, Role).

% Team determination
enemyTeam(T) :- inspectedEntity(_, T, _, _, _, _, _, _, _, _).
enemyTeam(T) :- not(team(T)), T \= none.

% Defines when an agent is disabled
disabled :- health(0).

% Predicates for determining when a node or its neighbor needs surveying
needSurvey(Vertex) :- vertex(Vertex,_,NBs), (NBs = []; member([unknown,_], NBs)), !.
needSurvey(Vertex) :- not(vertex(Vertex,_,_)).
neighbourNeedSurvey(ID) :- currentPos(Here), neighbourNeedSurvey(Here,ID).
neighbourNeedSurvey(Vertex,ID) :- vertex(Vertex,_,List), member([_,ID],List), needSurvey(ID).

% True when an optimum is found and it is time to swarm
optimum :- optimum(_), !, timeToSwarm.

% Random predicates. random/3 with float inputs should work, but it doesn't!
randomFloat(R) :-  R is (random(65391)/65391). % There seems to be a bug when using the built-in random/3 predicate
randomInt(N,R) :- randomFloat(X), R is floor(X*N).
randomElement(List, Elem) :- length(List,N), N > 0, randomInt(N,R), nth0(R,List,Elem).

% Defines whether an enemy is to be considered dangerous for sure
dangerousEnemy(Id) :- inspectedEnemy(Id, 'Saboteur'), !.
dangerousEnemy(Id) :- not(inspectedEnemy(Id, _)), !, findall(Id2, inspectedEnemy(Id2, 'Saboteur'), List), length(List,N), N < 4.
% Enemy is passive when disabled, can also be used on allies.
passiveEnemy(Id) :- visibleEntity(Id,_,_,disabled), !.
passiveEnemy(Id) :- inspectedEnemy(Id,Role), !, Role \= 'Saboteur'.
passiveEnemy(Id) :- not(inspectedEnemy(Id,_)), !, findall(Id2, inspectedEnemy(Id2, 'Saboteur'), List), length(List, N), N == 4.

% Short predicate to extract the most useful information from an inspected enemy
inspectedEnemy(Id,Role) :- inspectedEntity(Id, _, Role, _, _, _, _, _, _, _).

% Vertex value checks (checks for unknown before evaluating arithmetic operation)
vertexValueGT(A, B) :- A \= unknown, B \= unknown, A > B.
vertexValueGE(A, B) :- A \= unknown, B \= unknown, A >= B.

% Sum of the values of all vertices in a list
vertexListSum([], 0).
vertexListSum([H|T], Sum) :- vertexValue(H,V), V == unknown, vertexListSum(T,S), Sum is S+1.
vertexListSum([H|T], Sum) :- vertexValue(H,V), V \== unknown, vertexListSum(T,S), Sum is S+V.

% Get your swarm position
hasSwarmPos(X) :- swarmPosition(X), X \= unknown.

% (Optimums are now calculated from the belief base.)
% Optimums are vertices that are maximas such that no other vertex with a higher value exists, which is true of the vertices with value 10.
% No local maxima n with value < 10 exists (with very high probability) because of the map generation algorithm.
optimum(X) :- vertex(X,10,_).

% The effect (in percent of non-ranged effect) and effective range of ranged actions
expectedEffectiveRange(survey,ER) :- visibilityRange(VR), ER is (VR-1)/4+1.
expectedEffectiveRange(Action,ER) :- member(Action,[probe,inspect,attack,repair]), visibilityRange(VR), ER is VR/4.
effectCalc(MV,VR,0,MV).
effectCalc(MV,VR,Dist,Effect) :- Dist > 0, Effect is round((MV-1)/VR^2*(VR-Dist)^2+1).
rangedAttackEffect(Dist,0.0) :- strength(0).
rangedAttackEffect(Dist,Percent) :- strength(MV), MV > 0, visibilityRange(VR), effectCalc(MV,VR,Dist,Ef), Percent is Ef/MV.
rangedRepairEffect(Dist,Target,Percent) :- role(Target,R), member(R,['Inspector','Repairer']), visibilityRange(VR), effectCalc(6,VR,Dist,Effect), Percent is Effect/6.
rangedRepairEffect(Dist,Target,Percent) :- role(Target,R), member(R,['Saboteur','Explorer']), visibilityRange(VR), effectCalc(4,VR,Dist,Effect), Percent is Effect/4.
rangedRepairEffect(Dist,Target,Percent) :- role(Target,'Sentinel'), visibilityRange(VR), effectCalc(1,VR,Dist,Effect), Percent is Effect/1.
