%% Explorer specific knowledge

needProbe(Vertex) :- vertex(Vertex,unknown,_).
needProbe(Vertex) :- not(vertex(Vertex,_,_)).

% True when we should decide swarm positions
timeToDecideSwarm :- decidedSwarmAt(OldS), step(NewS), D is NewS - OldS, D >= 60, !.
timeToDecideSwarm :- swarmPosition(unknown), !, optimum(X), calcZoneValue(X,V), V >= 70.

% True when it is time to swarm. It differs from Explorers and the others 
timeToSwarm :- not(role('Explorer')), swarmPosition(Opt), Opt \= unknown, !.
timeToSwarm :- role('Explorer'), optimum(_), step(Cur), Cur > 150.

% Finds the optimum nodes that can contain a swarm with the largest
% potential values as defined by calcZoneValue
bestOptimums(List,Opts) :- findall((ValSum,Swarm), (member(Swarm,List), calcZoneValue(Swarm,ValSum)), L), sort(L,S),
				length(S,N), nth1(N,S,(MaxVal,_)), Limit is round(0.65*MaxVal), bestOptimumsAux(S,Limit,L2), sort(L2,Opts).
bestOptimumsAux([],_,[]).
bestOptimumsAux([(Val,Opt)|T],Limit,[Opt|Rest]) :- Val >= Limit, bestOptimumsAux(T,Limit,Rest).
bestOptimumsAux([(Val,_)|T],Limit,Rest) :- Val < Limit, bestOptimumsAux(T,Limit,Rest).

% Calculates the sum of the values for all the neighbors, and their neighbors, and the vertex O, around the vertex O
calcZone(O,S) :- findall(N, (neighbour(O,_,N)), L1), findall(N, (member(M,L1), neighbour(M,_,N)), L2), union(L1,L2,L3), sort(L3,S).
calcZoneValue(O,V) :- calcZone(O,L), vertexListSum(L,V).

% Find all optimums that are not already in use
allOptimums(Opts) :- allOptimums(Opts,[]).
allOptimums(Opts,Ignore) :- findall(V, (optimum(V), not(member(V,Ignore)), not((neighbour(V,N),member(N,Ignore)))), Opts), length(Opts,N), N > 0, !.

% Choose the best optimums
decideOptimums(Opts) :- allOptimums(L), !, bestOptimums(L, Opts), !.


%% Saboteur specific knowledge

% Used by the harassment strategy
% A possible harassment vertex is a high-value vertex that is owned by the enemy and therefore probably contains a swarm
timeToHarass :- me(Me), hasLowestRoleRank(Me), step(N), N > 60.
possibleHarassVertex(Pos) :- findall(V, (enemyStatus(EID,V,normal),	not(inspectedEnemy(EID,'Saboteur')), not(inspectedEnemy(EID,'Repairer')), notLargeBattle(V)), L), L \= [], randomElement(L,Pos), !.

largestZone([],0,_).
largestZone([H|T],Val,V) :- calcZoneValue(H,X), largestZone(T,XT,VT), (X > XT -> (V = H, Val = X); (V = VT, Val = XT)).

% If we have defeated the enemy near the harass vertex then the harass is over.
% Alternatively if we have harassed for a long time (> 50 steps) then we should do something else.
% It is important note that the harass/1 predicate cannot be true when adopting a harass goal. 
% Otherwise the agent won't adopt the goal! As a workaround, if N >= 75 then the predicate fails. 
% So in the time between 50 =< N < 75 the agent cannot adopt a new harass goal.
harass(V) :- (currentPos(V) ; (currentPos(P), neighbour(V,P))), not(enemyStatus(_,V,normal)), not((neighbour(V,NB), enemyStatus(_,NB,normal))), harassStart(S), step(Cur), N is Cur - S, N < 75.
harass(V) :- harassStart(S), S \= 0, step(Cur), N is Cur - S, N > 50, N < 75, vertex(V,_,_).

% When the enemy is disabled, the hunt is over
timeToHunt :- me(Me), hasLowRoleRank(Me), not(hasLowestRoleRank(Me)), step(N), N > 100.
hunt(ID) :- enemyStatus(ID,_,disabled).

% To determine which enemies are on the current position
enemyHere(ID) :- currentPos(Vertex), visibleEntity(ID,Vertex,Team,_), enemyTeam(Team).

% To deterine which enemies are close to the current position
enemyNear(ID,Pos) :- currentPos(Pos), enemyHere(ID).
enemyNear(Id,Pos) :- neighbour(Pos), visibleEntity(Id,Pos,Team,_), enemyTeam(Team).

% To determine when a non-disabled enemy is at your position
enabledEnemyHere(Id) :- currentPos(Vertex), visibleEntity(Id,Vertex,Team,normal), enemyTeam(Team).

% when an non-disabled enemy is at or next to your position
enabledEnemyNear(ID,Pos) :- currentPos(Pos), enabledEnemyHere(ID).
enabledEnemyNear(Id,Pos) :- neighbour(Pos), visibleEntity(Id,Pos,Team,normal), enemyTeam(Team).

% A list of all locations near where there are enemies
enabledEnemiesNear(List) :- findall(Vertex,enabledEnemyNear(ID,Vertex),L), sort(L,List), List = [_|_].

% Short predicate for finding enemies worth attacking
enabledEnemy(ID,Vertex) :- enemyStatus(ID,Vertex,normal).

% Used for buying upgrades. Only buy if the second highest enemy Saboteur has a strength or health advantage and if enough time has elapsed.
timeToBuy :- step(Step), Step >= 140.
enemySaboteurSecondMaxStrength(Strength) :- findall(Str, inspectedEntity(_, _,'Saboteur', _, _, _, _, _, Str, _), L), msort(L, S), length(S, N), N > 1, sort([N,3],A), nth1(1,A,Index), nth1(Index, S, Strength), !.
enemySaboteurSecondMaxHealth(Health) :-        findall(Hp, inspectedEntity(_, _,'Saboteur', _, _, _, _, Hp, _, _), L),  msort(L, S), length(S, N), N > 1, sort([N,3],A), nth1(1,A,Index), nth1(Index, S, Health), !.

% If there are N-1 ally Saboteurs and N enemy Saboteurs at a vertex then we should not go there because we are not needed (i.e. if not(notLargeBattle))
largeBattleCalculator(V,AN,EN,AL) :- findall(EID, (enemyStatus(EID,V,_), dangerousEnemy(EID)), EL), !, findall(AID, (teamStatus(AID,V,_), role(AID,'Saboteur')), AL), !, length(EL,EN), length(AL,AN).
largeBattle(V,AL) :- largeBattleCalculator(V,AN,EN,AL), AN >= EN, AN \= 0, EN \= 0, !.
notLargeBattle(V) :- largeBattleCalculator(V,_,0,_), !.
notLargeBattle(V) :- largeBattleCalculator(V,AN,EN,_), ANPlusUs is AN + 1, ANPlusUs < EN, !. % AN+1 to prevent us from creating a large battle


%% Repairer specific knowledge

% Predicate that returns disabled allies near or on the current position
disabledAllyNear(ID,Here) :- currentPos(Here), team(Team), me(Me), visibleEntity(ID,Here,Team,disabled), ID \= Me, !.
disabledAllyNear(ID,Vertex) :- team(Team), neighbour(Vertex), visibleEntity(ID,Vertex,Team,disabled), !.
disabledAllyNear(ID,Vertex) :- currentPos(Here), team(Team), visibleEdge(Here,Vertex), visibleEntity(ID,Vertex,Team,disabled), !.

% The repairing(ID) goal. 
% When the injured agent is no longer disabled, then the goal has been achieved.
% A repair goal should never be adopted unless there exists a path between the repairer and the injured agent. 
repairing(Agent) :- agent(Agent), not(teamStatus(Agent,_,0)). 


%% Inspector specific knowledge

% Predicate that returns uninspected agents close to the inspector
% This also makes sure enemy saboteurs are suitable for inspection again when last inspection is older than 50 steps
uninspectedNear(Agent) :- visibleEntity(Agent,Vertex,Team,_), enemyTeam(Team), (currentPos(Vertex) ; neighbour(Vertex)), 
	(not(inspectedEntity(Agent,_,_,_,_,_,_,_,_,_)); ( inspectedEnemy(Agent, 'Saboteur'), lastInspect(Agent,LI), step(S), LI2 is LI + 50, LI2 < S)).
uninspectedEntity(Agent) :- not(inspectedEntity(Agent,_,_,_,_,_,_,_,_,_)).
