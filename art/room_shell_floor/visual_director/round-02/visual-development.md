# Reconstructed carpet Visual Director — round 02

**Asset:** `room_shell_floor` · **source:** `photo_holder/Sample (1).jpg` and `rooms/room_photo_luna.json` · **status:** corrected image target ready for 3D review.

## What changed after v001

The v001 Godot production render at [room scale](../../../iterations/v001/render-runs/run-002/room-scale.png) was about RGB 242/236/231 in clear carpet patches, versus RGB 202/199/193 for the prior room material at the same locations. The registered [detail view](../../../iterations/v001/render-runs/run-002/asset-detail.png) was also occluded by the central green floor seat. The original approved swatch’s opposite 32-pixel edge bands differed by mean 48.3 levels horizontally and 50.5 vertically, which became a repeated seam. Candidate `room_shell_floor-v001` is recorded as continue, not promoted.

## Target and pixel review

The updated target edits the first carpet direction to lower the white-loop contrast slightly while preserving dense short residential pile and warm gray-beige color. A deterministic 48-pixel wrap blend was then applied to the image-generated swatch. The target is 1254 × 1254 pixels with RGB mean 140.4/129.9/120.5 and standard deviation 43.9. First and last pixel columns and rows now match within a maximum one RGB level; mean edge delta is 0.0. The blend occupies only a narrow edge band and does not add a border, motif, or seam.

[Approved target r02](approved-target-r02.png) · [image-generated source before edge blend](candidates/carpet-tileable-r02.png)

| Check | Pixel evidence | Review |
|---|---|---|
| Material identity | Dense, short gray-beige pile; no broad motif or color tile. | Pass for target handoff.
| Source color | Warm muted gray-beige; exact fiber and pile height remain uncertain. | Pass with source uncertainty recorded.
| Repeat edges | Maximum opposite-edge difference 1 level; mean 0.0 both axes. | Pass for tile handoff.
| Tile pattern | No plank, stripe, rug border, or directional motif. | Pass.
| Room geometry | Target contains no geometry; RoomDefinition remains authoritative. | Not assessed from pixels.

**3D handoff:** copy this approved albedo without repainting, derive only a restrained normal map and roughness map, tint using the recorded recipe, and capture the clear southwest carpet patch. Do not promote until the full room render approaches the source value and the close image proves the pile without a visible repeat.
