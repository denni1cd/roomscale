# Painted wall finish Visual Director — round 02

**Asset:** `room_shell_wall_finish` · **source:** `photo_holder/Sample (1).jpg` and `rooms/room_photo_luna.json` · **status:** corrected image target ready for 3D review.

## What changed after v001

The v001 [Godot close view](../../../iterations/v001/render-runs/run-001/asset-detail.png) showed repeated square tonal patches at the recorded 12-inch world repeat. The target edge bands differed by mean 6.1 RGB levels horizontally and 6.7 vertically. Candidate `room_shell_wall_finish-v001` is recorded as continue, not promoted. The target stays a plain green paint texture; wall paneling or joints would contradict the source.

## Target and pixel review

The approved color and restrained fine paint stipple are kept, then a deterministic 48-pixel wrap blend was applied. The 1254 × 1254 target has RGB mean 25.5/67.6/57.3 and standard deviation 18.6. First/last pixel columns and rows match exactly (maximum and mean edge delta 0).

[Approved target r02](approved-target-r02.png) · [source target before edge blend](candidates/paint-tileable-r02.png)

| Check | Pixel evidence | Review |
|---|---|---|
| Source color | Deep muted forest-green/teal; paint formula and exact sheen remain uncertain. | Pass for target handoff.
| Texture | Subtle fine stipple; no added panel geometry or broad motif. | Pass.
| Repeat edges | Maximum and mean opposite-edge difference are 0 levels on both axes. | Pass for tile handoff.
| Architecture | Target depicts material only; RoomDefinition openings, trim, and cutaway remain separate. | Not assessed from pixels.

**3D handoff:** copy the approved albedo unchanged, derive restrained normal/roughness maps, and evaluate a 24-inch world repeat on an unobstructed south-wall patch. Do not promote if the paint reads as patchwork or obscures trim and opening joins.
