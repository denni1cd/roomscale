# Multi-civilization readiness audit

This is a static code audit, not an implementation or a two-civilization experiment.
The founder campaign exercises one civilization in one room per fresh process.
No second civilization was created. Difficulty estimates concern an independent
second civilization sharing the *same physical room*, not two separate room scenes.

The main obstacle is shared-world resource authority and ownership. The economy,
governor, population and capability objects already have mostly instance-local
state. However, instantiating them twice would duplicate finite room resources
and salvage yields, while both instances modify the same object visuals and floor.
Naming another simulation node alone would not make this safe.

## Assumption inventory

| Assumption | Evidence / conflicting code path | Difficulty | Required future boundary |
|---|---|---|---|
| One civilization simulation | `pipeline_proof.gd:start_civilization` creates named `CivilizationSimulation`; `civilization_simulation.gd:configure` looks up scene siblings by fixed names and adopts all `_citizens` | Moderate | Civilization registry, own citizens and injected service references |
| One settlement scene | `pipeline_proof.gd:_build_settlement`, `_process` address `Settlement`; generated development visuals attach directly to room scene | Moderate | Settlement roots and globally distinguishable structure identities |
| One settlement origin | `RoomDefinition.prepare_start` derives all anchors from one `start.origin`; `development.center` reads that single origin | Easy for instance configuration; Moderate for input contract | Per-civilization start configuration, own compatibility anchors |
| One autonomous governor | Each simulation owns `Governor.new`, but enablement uses process-wide `ROOMSCALE_FISHBOWL` | Easy | Per-instance configuration instead of launch environment |
| One economy | Each simulation has local `Economy.new`; tickets use local owner strings (`citizen:N`, `development_NNN`, `traversal`) | Moderate | Separate inventories plus shared resource authority and fully scoped transaction owners |
| One population pool | Population system is local, but creation IDs and room `_citizens` grow from one array | Moderate | Per-population membership plus room-wide entity lookup |
| One task coordinator | Simulation fixed lookup `TaskCoordinator`; coordinator has one `civilization` backlink | Moderate | Inject one owning coordinator per civilization; no room-wide name lookup |
| One construction system | Simulation fixed lookup `ConstructionSystem`; one project state, target, workers and economy | Moderate | Per-project/owner instances, shared spatial reservation authority |
| One traversal project | `construction_system.gd` stores one `project_created`, `target_region`, deployment and component state | Hard | Multiple infrastructure projects with explicit public/private access policy |
| One depot | `depot_station` is one coordinate; development deliberately preserves one pickup apron; inventory has no physical depot dimension | Moderate | Depot/service ownership and inventory location policy |
| One workshop namespace | `has_capability` correctly uses local completed projects, but reads one scene's initial infrastructure and fixed simulation from project gating | Moderate | Explicit owning simulation for each prerequisite check |
| One housing capacity pool | `needs.shelter_capacity`, `rest_capacity`, `resting` and `citizen.needs.sheltered` are instance-local but ID/index based | Moderate | Housing ownership and shelter/rest assignment to own agents |
| One journal | `Journal.new` is per simulation; events contain event ID, kind, evidence, focus but no civilization ID | Easy locally; Moderate when aggregating | Civilization attribution and composite event identity |
| One resource pool | `Resources.configure` imports *every* room object's contents independently into local remaining/reserved/extracted dictionaries | Hard | One authoritative finite source per physical room object; access/ownership claims |
| One salvage authorization state | `Salvage.configure` creates fresh stage/progress/yield state for every harvestable object; `apply_salvage_stage` changes room-wide visuals/navigation | Hard | World-owned salvage stage machine, civilization work permissions, yield destination |
| One citizen ID namespace | `population.evaluate` allocates `sim.citizens.size`; names `Citizen%02d`; many lookups use node names or `citizens[id]` | Moderate | Scoped IDs or globally unique IDs; stop assuming ID equals array index |
| One project ID namespace | `development.request` uses `development_%03d` from local project count; visual root names and economy ticket owners reuse it | Moderate | Civilization/project composite IDs and globally scoped spatial obstacles |
| One task ID namespace | Coordinator `_next_task_id` starts at one; IDs are safe only while bound to their own coordinator | Moderate | Composite identity for cross-system references and diagnostics |
| One HUD civilization target | `CivilizationUI.configure`, `FishbowlHUD.configure` bind a controller; room selection and controls look up fixed `CivilizationSimulation` | Moderate | Selectable active civilization; controls and inspections route by owner |
| One shared world/navigation authority | Each `_build_population` creates one floor/surface navigation; salvage and completion mutate its private copied definition and rebuild it | Hard | Shared authoritative obstacle state/revisions and route invalidation across all populations |
| One global room/start definition | The schema has one `civilization`, `start`, `spawn`, `target_surface_id`, landmarks and activity stations | Moderate | Separate room geometry from civilization configuration |

## Direct answers

**Can resources currently be owned by a civilization?** Inventory can be held in
a simulation's economy, but finite sources and salvage do not have civilization
ownership fields, world reservations, or access rules. Bundle `citizen_id` is a
local haul reservation, not civilization ownership. An economy ticket's owner
identifies a consumer/project, not a civilization. Source reservations are
amounts per resource, not individual worker or civilization claims.

**Can two task coordinators safely operate against the same floor navigation?**
Read-only path queries are plausibly shareable: floor A* does not store worker
ownership and citizens do not implement mutual collision avoidance. Safe concurrent
operation after construction/salvage is unproven. Grid rebuilding must publish
changes and invalidate routes for both populations. Today development repaths only
`sim.citizens`; salvage changes its controller's navigation directly. Separate
navigation copies would diverge. Classify path-query sharing as Unknown until a
future experiment; mutation and invalidation are a Hard design boundary.

**Can settlements have independent capability state?** The `count`/completed-project
model already supports instance-local capability accounting. Initial infrastructure,
construction controller ownership and scene lookup need separation. Capabilities
are not a global static variable, which is a useful foundation.

**Can construction projects coexist?** One development system serializes its own
projects using `active`. Two systems could create independent project records, but
uncompleted sites are not reserved across systems. `valid_site` sees its own
projects and world obstacles; planned projects of another civilization would be
invisible until completion. Both could approve the same site. Physical delivery
and prerequisite checks also need explicit owner routing.

**Can two populations share one room safely?** Not as currently wired. All room
citizens are adopted by the one simulation. `claim_for`, stage cancellation and
construction dispatch find `CitizenNN` siblings; traversal reuse scans every room
child whose name begins with Citizen. A second population could be selected by the
wrong coordinator. Shared-source duplication is an independent conservation risk.

**Would citizen IDs collide?** Yes, each new population starts from zero. Godot
may rename duplicate sibling nodes, which makes fixed-name lookup incorrect even
if the nodes survive. `release` and `routine_score` indexing `citizens[id]` requires
contiguous stable IDs; deletion is also a future concern even with one civilization.

**Would event/UI systems know which civilization produced an event?** A bound
HUD can infer its controller. An event record by itself cannot identify the
civilization, and event IDs/suppression keys overlap between journals. Room-level
selection, narrative aggregation and camera direction would need attribution.

**Does salvage imply global ownership?** It behaves as the sole authorized
civilization controlling the room object. Authorization is simulation-local, but
geometry/visual side effects address `RoomObjects/<id>`. Two local stage ledgers
would describe the same physical object differently and could award its yield twice.

**Would one civilization consume resources intended for another?** There is no
such intent/ownership model. Each resource controller sees all room sources. Simply
duplicating controllers would be worse: each would believe the original quantity
was independently available, creating an effectively duplicated world supply.

**Is traversal globally shared or civilization-owned?** Physically it is a link
between room regions. Construction/economy state belongs to the currently bound
controller, but the surface navigation link has no owner or permission metadata.
A shared navigator would grant all agents access; separate navigators would conceal
real shared geometry from the other population. Public infrastructure versus private
rights must be a deliberate future rule.

**Is a second civilization mainly an instance problem?** No. Instance injection
and namespaces are necessary, but resource authority, site reservation, shared
navigation updates and infrastructure access are deeper world-ownership problems.

## Other forward risks

- `carrying_capacity` sums all remaining resources regardless of current reachability;
  founder progression relies on the reachable elevated target eventually unlocking.
- Founder storage has a fixed geometric relationship to the origin. This milestone
  fixes one rest-apron conflict; it does not supply arbitrary depot placement.
- The room validator proves traversal approaches/source placement, not the entire
  evolving settlement plan. A shared-world site planner must reason about future
  anchors and other civilizations' pending structures.
- Iteration order affects worker decisions. Changing global registration order in a
  multi-civilization world could change otherwise deterministic outcomes.
- Established POC45/46 housing/activity anchors can lie inside initial module
  footprints. Their legacy path endpoint contract is preserved; founder worlds
  continuously enforce exterior legal citizen positions. This is a remaining
  compatibility boundary, not proof that arbitrary interior/exterior routes work.
- `Citizen._shared_meshes` and material caches are presentation sharing, not economy
  ownership. They should not be mistaken for simulation-global authority.

Do not start multi-civilization gameplay by duplicating the existing room scene
services. First separate authoritative world sources/obstacles from civilization
inventories, permissions, planners and populations. This recommendation introduces
no new gameplay or production code in this milestone.

## Hardening evidence relevant to future ownership

Seven reproduced defects show that correct economy instance state alone does not
make physical progression safe. Reserved future depot activity space matters;
coarse paths need validated physical connectors; failed navigation needs a tick
boundary; resource availability must agree with collection eligibility; derived
activity targets need physical placement checks; sub-grid aisles need explicit
connectors; and obstacle revisions must preserve an agent already on a traversal.
These are measured single-civilization defects, not speculative multi-civ results.

The midlink defect is especially relevant to shared navigation revisions. Current
development repaths only its own citizens on completion. The new route continues
from a physical point on an already deployed link and validates its floor exit;
it does not add civilization ownership or permission metadata to that link. A
future shared obstacle revision must notify every affected population and preserve
its traversal state. A local planner cannot safely assume all affected agents are
on its own floor.

Safe-salvage authorization is serialized: the governor refuses another object while
one authorized object's yields are still outstanding. `can_supply` totals remaining
safe stages; it does not reserve those yields across civilizations. Future shared
authority must distinguish projected capacity, authorization, actual extraction
and inventory receipt, and must report inaccessible outstanding work rather than
pretending another civilization's projection is available local inventory.

Population arrival currently allocates contiguous local IDs and a safe floor cell
connected to its own depot. That is useful instance behavior, but there is no
agent collision/reservation model for simultaneous arrivals from other populations.
The present bounded-movement and unique-ID evidence should not be read as
inter-agent collision avoidance or multi-civilization fairness.
