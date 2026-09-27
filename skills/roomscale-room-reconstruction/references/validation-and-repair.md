# Validation and repair

The normal `RoomDefinition` validator is authoritative. Review `scripts/room_definition.gd` and `docs/RoomDefinition_Contract.md` for current checks. Do not claim a room is valid based only on visual inspection or a successful JSON parse.

The repository currently has:

- `TEST_ROOM_SCALE_FAST.ps1`, which checks Room A and Room B definitions, malformed cases, generated obstacles and targets, reachable approaches/sites, navigation connectivity, and task-history bounds;
- `VALIDATE_ROOM_SCALE.ps1 -Room <candidate.json>`, which runs structural and runtime-navigation validation for an arbitrary project-local RoomDefinition file, emits a structured `ROOMSCALE_VALIDATION_PASS`/`ROOMSCALE_VALIDATION_FAIL` JSON result, and saves the complete output log. It also accepts an existing room ID for regression checks;
- `TEST_ROOM_SCALE.ps1 -Room room_a` or `-Room room_b`, which runs a complete production gameplay scenario for those existing definitions. `-Room` also accepts a project-local JSON file path for candidate production runs; its filename without `.json` must match the definition's `id`.

The fast command still exercises the legacy rooms plus deterministic schema v2 fixtures. A full production gameplay run is a later integration check, not a substitute for structural validation.

For example, the deterministic v2 fixture is validated with `./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/fixtures/m2_fixture.json -LogPath verification/poc2/m2-validator-fixture.log`. A malformed-input check is recorded by `./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/fixtures/m2_invalid.json -LogPath verification/poc2/m2-validator-invalid.log`; that intentionally invalid candidate must produce structured diagnostics and a nonzero exit status. For any candidate file, its basename without `.json` must match the RoomDefinition `id`.

For each validator attempt:

1. Save the model's output unchanged as the candidate and keep a separate copy of every failed version.
2. Run `VALIDATE_ROOM_SCALE.ps1 -Room <exact candidate path>` and preserve its complete structured diagnostics beside that candidate.
3. If validation fails, return the unchanged candidate and diagnostics to the same reconstruction context. Ask for the smallest correction needed to satisfy the contract while preserving photo-supported geometry and appearance.
4. Save the repaired output as a new attempt. Rerun validation and retain the result. Use no more than three repair attempts unless a concrete validator defect is found and corrected.
5. Never fix JSON manually, use Godot as a level editor, or bypass the validator. If the validator rejects a coherent definition because the general contract or validator is defective, report the exact error, repair the generalized contract/tooling, and rerun the loop.

A pass requires the validator's explicit success result for the candidate. Record the validator version/command, candidate path, attempt number, and evidence path in the reconstruction notes.
