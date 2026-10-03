# Production visual review

Inspected the actual PNG content, not just file existence. Final eight-day captures
are under `final-visuals/scenario-visuals/`; day-sixty captures are under
`final-stability/stability-60days-visuals/`. Every capture has a production-state
JSON sidecar. Capture framing only changes the camera; it never drives simulation.

| Checkpoint | Inspection finding |
| --- | --- |
| Initial settlement | Original districts/furniture present, 50 citizens, zero wood/metal and 0.67 water days. Governor shows initial observation before first periodic decision. |
| Autonomous water crisis | HUD shows SURVIVAL and Secure Water with reserve evidence; traversal initially unavailable. |
| Autonomous salvage | Real worker at the bookcase edge; intermediate stage replaces original panels with reduced frame; original object later disappears. |
| Material hauling/climbing | Close views show carried material and citizen physically on the deployed cable above the floor. |
| Water recovery | Elevated water route persists, water forecast exceeds two days, governor returns stable; first real housing foundation begins. |
| Housing project/frame/shell/complete | Foundation plate, posts/beams, walls and roof/front are visibly different; final capacity rises from 50 to 60. |
| Workshop frame/shell/complete | Posts/beams progress to teal walls, then roof/front/chimney; module is distinct from housing and retained beside the original settlement. |
| Construction work | Final close-up shows the worker's tool at the real assembly workpiece rather than posing toward traversal machinery. |
| First cohort | Production HUD shows 55 citizens and corresponding 110 food/165 water daily demand, within completed shelter. |
| Multiple structures | Two houses plus workshop visibly surround the original settlement by day 2.65; four houses plus workshop at eight days. |
| Altered room | Bookcase and further finite material objects are removed by production salvage; original room layout/desk/resource dependency remain recognizable. |
| Mature sixty-day settlement | Seven houses and one workshop visibly surround the original four districts; HUD shows 120 population/shelter and finite-material growth pause history. Wide room view clearly differs from startup. |
| HUD | Reserves, demand, shelter, governor/reason, objective, traversal, development/stage, macro events, camera toggle and speed controls remain readable. |

The first close-up captures had stale camera-dependent detail visibility, hiding
worker tools when the simulation was paused. Production rendering now offers a
presentation-only LOD refresh, and development work uses its own assembly target.
Re-rendered affected close-ups were inspected; the construction hammer/workpiece
and citizen detail are visible. The camera/LOD fast tests verify unchanged needs,
positions and authoritative time. Earlier captures remain separately identified.

Intentional limits: citizens are half an inch tall and look tiny in room overviews;
close-up captures provide work evidence. Buildings use simple predetermined meshes,
with no interiors or freeform assembly. Camera decisions are state/event driven;
verification capture labels choose views for review without affecting simulation.
