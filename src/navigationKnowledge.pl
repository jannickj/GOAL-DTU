% Finds a list of all neighboring nodes of a given node
neighbours(V,Ns) :- findall(N, neighbour(V,N), Ns), !.

% Finds all neighboring nodes of the current position
neighbour(Neighbour) :- currentPos(Id),!, neighbour(Id,_,Neighbour).

% Finds all neighboring nodes of a given node
neighbour(Id,Neighbour) :- neighbour(Id,_,Neighbour).

% Finds all neighboring nodes of a given node, and the weight of their connection
neighbour(Id,Weight,Neighbour) :- vertex(Id,_,List), member([Weight,Neighbour],List).

% This predicate determines when a node is to be considered safe to stand on, this means no unknown role agent or saboteur can be at this location 
safePos(P) :- not((visibleEntity(A, P, T, normal), enemyTeam(T), not(passiveEnemy(A)))), 
	not((neighbour(P, P2), visibleEntity(A2, P2, T, normal), enemyTeam(T), inspectedEnemy(A2,'Saboteur'))).

% Determines if the agent is the only agent on its position
allAlone :- not( (currentPos(Pos), me(Me), team(Team), !, visibleEntity(ID, Pos, Team ,_), Me \= ID ) ).

% Compares agents names to find which name has a higher 'value'
compareAgents(Agent1,Agent2,Agent2) :- Agent1 @< Agent2.
compareAgents(Agent1,Agent2,Agent1) :- Agent1 @> Agent2.

% Returns the rank (based on its name) of an agent compared to all other agents on its node
agentRankHere(Rank) :- currentPos(Here), me(Name), team(Team), !, 
	findall(Agent, visibleEntity(Agent,Here,Team,normal), Agents), agentRank(Agents,Name,Rank).
	
% An agents rank (i.e. index) in the list List
agentRank(List,Agent,Rank) :- nth0(Rank, List, Agent), !.

% Predicate that selects a Neighbour on index Number from the list of Neighbours, useful in combination with agentrank for splitting up, agent with rank 0 will not get a neighbor
selectNeighbour(List, Number, Neighbour) :- length(List, Size), Num is mod(Number,Size), nth1(Num, List, Neighbour), !.

% Predicate that selects a Destination on index Number from the list of Destinations, useful for splitting up in combination with agentrank when multiple destinations are available
selectDestination(List, Number, Destination) :- length(List,Size), Num is mod(Number,Size), nth0(Num, List, Destination), !.

% Short predicates for vertex information
vertexValue(Id,Value) :- vertex(Id,Value,_).
vertexValue(Id,unknown) :- not(vertex(Id,_,_)).

% Workaround for the action specifc warning from the action "goto":
% "WARNING: getPrecondition for UserSpecAction does not support multiple specifications"
% Saboteurs need to have >=11 energy because it would be unwise to not be able to attack after moving. Otherwise they would die if they walk to a vertex with an enemy Saboteur.
canGoto(Here, There) :- role('Saboteur'), neighbour(Here,Weight,There), enemyTeam(T), visibleEntity(ID,There,T,normal), dangerousEnemy(ID),!, (Weight == unknown -> W is 11 ; W is Weight+2), energyGE(W).
canGoto(Here, There) :- neighbour(Here,Weight,There), energyGE(Weight), !.
canGoto(Here, There) :- not(neighbour(Here,There)), visibleEdge(Here,There). 

% The agent's rank amongst its peers on the team with the same role
agentRoleRank(Agent, Rank) :- role(Agent, Role), findall(A, role(A, Role), L), sort(L, S), agentRank(S, Agent, Rank).
agentEnabledRoleRankHere(Agent, Rank) :- currentPos(Pos), team(T), role(Agent, Role), findall(A, (role(A, Role), visibleEntity(A, Pos, T, normal)), L), sort(L, S), agentRank(S, Agent, Rank).
hasHighestRoleRank(Agent) :- agentRoleRank(Agent, Rank), Rank is 0.
hasLowRoleRank(Agent) :- agentRoleRank(Agent, Rank), (role(Agent,'Saboteur') -> Rank > 1 ; Rank > 3).
hasLowestRoleRank(Agent) :- agentRoleRank(Agent, Rank), (role(Agent,'Saboteur') -> Rank is 3 ; Rank is 5).

% Used to find all visible edges around a vertex
visibleEdgesList(Id1, Array) :- findall([unknown, Id2], (percept(visibleEdge(Id1,Id2)); percept(visibleEdge(Id2,Id1))), L), !, sort(L,Array).
