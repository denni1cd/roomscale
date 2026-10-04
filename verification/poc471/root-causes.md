# Production failure investigations

## BUG-471-01 — Shelter rest apron permanently blocks bootstrap depot (High)

Classification: C, production placement bug. Reproducer: POS-006, seed 471005,
Mixed Obstacle Routing. The definition passes schema, production navigation,
reachable finite material and primitive shelter/depot feasibility checks. The
initial campaign completes shelter at 150.9s at `(0,0,14)`, with its work/housing
anchor at `(0,0,23)`. No depot project is ever created in 4800s.

Production `select_site` reserves 22 inches around the future depot center
`(0,0,37)` before choosing shelter, but does not reserve space for the *future
rest slots* created by that shelter. Completion sets housing_station to the
shelter target and raises rest_capacity to five. Rest slots derived at approximately
z=39 intersect the depot's required clear apron. `valid_site` then correctly
rejects the depot on every retry. This is permanent geometry, not a passing
citizen, material shortage, insufficient worker labor, or slow hauling.

The initial snapshot proves the fixed depot was valid before shelter completion.
Final diagnostics show one real completed shelter, no active project, an
observable site refusal, and eventual water crisis. Conservation remains intact.
Adding food/water would only delay the same failure.

Planned minimal repair: exclude primitive shelter candidates whose prospective
housing/rest anchors occupy the already reserved bootstrap depot apron. Retain
the actual depot pickup, inventory, physical delivery, material costs and timers.
Do not relocate citizens or grant infrastructure. Re-run this seed, canonical
POC47, shared regressions and the full campaign after the fix.

Exact pre-fix reproducer:

```powershell
./TEST_ROOM_SCALE_POC471.ps1 -Mode Reproduce -Scenario verification/poc471/initial/POS-006/config.json -OutputDirectory verification/poc471/prefix-reproduction -Workers 1
```
