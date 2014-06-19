%% Code for the different algorithms presented here is adapted from: http://colin.barker.pagesperso-orange.fr/lpa/dijkstra.htm


heuZero(Node1,Node2,Heu):- Heu is 0.

cleanWeight(unknown,6):-!.
cleanWeight(Weight,Weight).

adjacentNode(CurNode, (Weight, AdjNode)):- neighbour(CurNode,NWeight,AdjNode),cleanWeight(NWeight,Weight).
adjacentNodeWeightOne(CurNode, (1, AdjNode)):- neighbour(CurNode,_,AdjNode).

goalReached(Pos, Pos).
unknownNodeReached(Pos, _):- vertex(Pos,_,N), member([_,Pos2],  N), \+ vertex(Pos2, _, _),!.
unprobedNodeReached(Pos, _):- vertexValue(Pos,unknown).
unprobedNodeReachedExChecks(Pos, _):- vertexValue(Pos,unknown),not(needExploring(unknown)), needExploring(List), member(Vertex,List), needProbe(Vertex).
unsurveyedNodeReached(Pos,_):- needSurvey(Pos).
repairerOnNodeReached(Pos,_):- teamStatus(NameAgent,Pos,_), role(NameAgent, 'Repairer'),!.
enemyOnNodeReached(Pos,_):- enabledEnemy(NameAgent, Pos), visibleEntity(NameAgent,_,_,_),!.
	
%% Dijkstra from S to T
% path(Vertex0, Vertex, Path, Dist) is true if Path is the shortest path from Vertex0 to Vertex, and the length of the path is Dist. The graph is defined by e/3. e.g. path(penzance, london, Path, Dist)
path(Start, Target, Path, Dist):- aStarSearch(Start, Target, 0, heuZero, adjacentNode,goalReached, Path, Dist).

pathShortest(Start, Target, Path, Dist):-aStarSearch(Start, Target, 0, heuZero, adjacentNodeWeightOne,goalReached, Path, Dist).

%% Dijkstra for closest unknown vertex
pathClosestUnknownVertex(Start, _, Path, Dist):- aStarSearch(Start, _, 0, heuZero, adjacentNode,unknownNodeReached, Path, Dist).

%% Dijkstra for closest non-probed vertex
pathClosestNonProbed(Start, NonProbedVertex, Path, Dist):- aStarSearch(Start, _, 0, heuZero, adjacentNode,unprobedNodeReached, Path, Dist).


%% Dijkstra for closest non-probed vertex, with some additional checks
pathClosestNonProbedWithExtraChecks(Start, NonProbedVertex, Path, Dist):- aStarSearch(Start, _, 0, heuZero, adjacentNode,unprobedNodeReachedExChecks, Path, Dist).

%% Dijkstra for closest non-surveyed vertex
pathClosestNonSurveyed(Start, NonSurveyedVertex, Path, Dist):- aStarSearch(Start, _, 0, heuZero, adjacentNode,unsurveyedNodeReached, Path, Dist).

%% Dijkstra for closest Repairer
pathClosestRepairer(Start, LocationRepairer, NameAgent, Path, Dist):- aStarSearch(Start, _, 0, heuZero, adjacentNode,repairerOnNodeReached, Path, Dist).

%% Dijkstra for closest Visible Enemy
pathClosestVisibleEnemy(Start, LocationEnemy, NameEnemy, Path, Dist):- aStarSearch(Start, _, 0, heuZero, adjacentNode,enemyOnNodeReached, Path, Dist).
  
