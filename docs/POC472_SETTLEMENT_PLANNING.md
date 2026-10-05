# POC 4.7.2 settlement placement

Founder development uses `settlement_site_planner.gd`. Five founders, finite source quantities, economic tickets, build costs, walking speed, fixed ticks, survival forecasts, growth gates and traversal gates retain their POC 4.7.1 rules. Planning produces coordinates and reservations; production citizens still extract, haul and build every project.

## Geometry and decision sequence

The first shelter requires a simultaneous certificate for shelter, depot, workshop and first housing. Four 12x10 physical yards each retain the existing four-inch access margin (20x18 apron). Search candidates come from the current floor grid and actual room/obstacle boundaries. All four exterior work sides are considered. The pickup stockpile stays at its existing physical coordinate; choosing a depot elsewhere never relocates goods. Real delivery tasks connect that stockpile to the selected depot work point.

Candidate aprons must stay inside the room and clear room objects, completed structures, other proposed/reserved aprons, active traversal, resource points, salvage access, existing project work targets and compatibility activities. Every prefix and the complete arrangement use an independent production navigation grid. Required targets must remain physically outside blocking geometry and connected to the existing pickup anchor. Traversal investigation approaches and its derived construction point are protected.

Rest points are selected on connected clear floor cells against the entire reserved layout. Their ordering uses distance to the shelter work point, then z, then x. The first plan reserves seven points; only five become usable upon actual shelter completion, and two more upon actual first housing completion. Further housing reserves two additional points. Existing rest points stay fixed; workers are never moved when planning or rebuilding navigation.

## Deterministic bounded search

Sites rank by squared distance to founder origin, then ascending z, then ascending x. Work sides use the same order. A depth-first founding search returns the first fully validated arrangement in this order. It evaluates at most 96 eligible site branches per depth and 2,048 navigation trials per decision. It is not a proof of global infeasibility when this bound is exhausted.

For compact candidate domains, an exact rectangle-union area bound rejects a prefix when the remaining legal apron coverage cannot contain the required number of disjoint yards. This is a necessary condition, never an acceptance shortcut. It avoids wasting navigation trials on equivalent combinations in narrow building pockets.

Plans run at development decisions, not every tick. Remaining sites and rest points are reused. Geometry with no feasible certificate is cached until the navigation definition changes. A currently occupied reserved site waits for natural citizen movement. Selection revalidates the cached arrangement. Immediately before completion, production validates current connectivity and active destinations again before consuming tickets or inserting the real obstacle. Navigation then repaths moving citizens through the existing floor and active grapple logic.

## Observability and verification

Each accepted decision records candidate examinations, navigation trials, rejection counts/reasons, nearest rejected alternatives, selected position/score/rank, future layout, connectivity, downstream feasibility and whether it reused a search. Reused decisions retain the original shared plan's search statistics. The observer reads these values; verification never changes planner rules.

`poc472_observer.gd` extends the prior conservation, movement, needs, labor, growth and capability observer. On every tick it checks actual construction delivery movement against blocking geometry. At each relevant geometry/project/reservation change it checks disjoint footprints, connected exterior work/delivery routes, future access and earned activity/rest points. The focused planner test compares identical starting states and snapshots physical state around preview/selection. A control run omits startup feasibility queries and continuous invariant checks; its final semantic fingerprint must equal the fully observed run.

The campaign loads all 95 retained POC 4.7.1 definitions, without generating replacements. It adds 31 placement inputs, including a small protected building pocket where central legal sites cannot fit the full chain, and a protected-aisle negative with a geometric impossibility proof. Original NEG-03 blocked only the previous fixed depot position: successful founding is now its physically correct outcome.

## Limits

The founder planner supports the existing rectangular floor, conservative rotated obstacle bounds, fixed yard sizes and one elevated target. Candidate discretization and search bounds can still miss feasible arrangements. The four-inch apron remains deliberately conservative; a corridor can be navigable yet too narrow for a yard. Legacy established settlements retain their previous placement/anchor contract. This change does not introduce multiple civilizations or independently owned world geometry, renewable supplies, resource relocation, mortality or expansion to other rooms.
