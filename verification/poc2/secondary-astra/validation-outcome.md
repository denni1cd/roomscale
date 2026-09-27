# Secondary Astra validation outcome

**PASS after two AI repair attempts.** The accepted file is `verification/poc2/secondary-astra/attempt_3/astra_room.json`. The original candidate and both failed candidates remain unchanged in their attempt directories with their own complete validator logs.

## Evidence

- Validator command: `./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/secondary-astra/attempt_3/astra_room.json -LogPath verification/poc2/secondary-astra/attempt_3/validator.log`
- Runtime version printed by validator: Godot 4.7.2.stable.official.ed1daf0bf.
- Validator script version: current local `VALIDATE_ROOM_SCALE.ps1`; no separate script version was reported.
- Final complete log: `verification/poc2/secondary-astra/final-validation.log` (copy of attempt 3 log).
- Explicit result: `ROOMSCALE_VALIDATION_PASS`, exit code 0, structural validation pass, runtime navigation validation pass.
- Derived result: 11 blocking obstacles, 2 reachable target approaches, valid construction site at [-20, 0, 38], target DESK_TOP on computer-desk.
- Full production gameplay and visual runtime review were not run.

## Attempts and repairs

1. Attempt 1 failed: eleven scalar navigation_padding fields required three-number vectors, and three elevated wall-decoration objects failed floor bounds.
2. Attempt 2 failed: scalar padding changed to [p, 0, p], and the three wall decorations received [0, 0, 0]. Only the same three bounds errors remained.
3. Attempt 3 passed: those three decorative panels moved three inches inward. Furniture, shell, target surface, settlement metadata, and all other geometry stayed unchanged.

## Skill usability findings

The portable contract enabled an independent photo-based candidate without consulting another reconstruction, project plans, verification outputs, or game source. Two documentation gaps affected first-pass validity:

- navigation_padding is described as nonnegative but its required three-number array shape is not specified.
- Thin wall-mounted visual props whose explicit geometric bounds fit inside the floor still failed bounds with zero padding. Moving them inward resolved the failure. After the successful repair, the coordinator confirmed the validator requires a one-inch interior floor-bound clearance that the portable contract omitted. No game/source code was inspected by this reconstruction context.

The wall-art workaround leaves the panels four inches from the wall. This is a disclosed visual compromise; a later revision could use the now-confirmed one-inch minimum clearance for a closer wall placement. The room-scale estimates, coarse hammock/lamp/seat archetypes, and other visual uncertainties remain as recorded in attempt_1/reconstruction-note.md. Validation proves structural and navigation acceptance, not photograph fidelity or full gameplay completion.

