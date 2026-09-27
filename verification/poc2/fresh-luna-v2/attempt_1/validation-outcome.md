# Validation outcome

The unchanged attempt 1 candidate was validated with:

`./VALIDATE_ROOM_SCALE.ps1 -Room verification/poc2/fresh-luna-v2/attempt_1/fresh_luna_room.json -LogPath verification/poc2/fresh-luna-v2/attempt_1/validator.log`

Attempt 1 failed because the validator did not accept its spawn metadata (`spawn requires a 3D center and positive horizontal footprint dimensions`). Attempt 2 changed the spawn footprint field to `dimensions`; structural validation then passed, but runtime navigation found only one reachable desk approach. Attempt 3 added two floor-space approach hints at the clear sides of the desk front and passed both structural and runtime-navigation validation.

Final validated candidate: `verification/poc2/fresh-luna-v2/attempt_3/fresh_luna_room.json`.

The final pass log is copied to `final-validation.log` in this folder. The complete original attempt 1 failure log remains `validator.log`. Godot validator runtime reported version 4.7.2.stable. No full gameplay test was run.
