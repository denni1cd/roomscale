# Batch 18 — Human-Room Architecture Backlog Review

## Scope and pixel review

Rechecked the exhausted trim r01 and French-door r03 episodes against their approved targets and actual Godot captures. Codex directly inspected the image pixels; this review is not attributed to Luna. Neither case received a new candidate or target because each episode has already used its three strategies and the current evidence does not justify repeating one.

For trim, the target has broad, restrained stained-wood faces and a small number of shallow transitions. v002 removes the warm material stripes and retains continuous brown faces, but its close capture still shows extra contour lines and no visible grain. v003 reduced the stored geometry from 92 to 72 triangles, yet the low-frequency grain and remaining profile transitions still create repeated lines. Keep v002 as best current review; neither profile is a production pass. See the [approved target](../../art/room_shell_trim/visual_director/round-01/approved-target-r01.png), [v002 baseboard](../../art/room_shell_trim/iterations/v002/render-runs/run-001/baseboard-profile-detail.png), [v002 crown](../../art/room_shell_trim/iterations/v002/render-runs/run-001/crown-profile-detail.png), and [v003 baseboard](../../art/room_shell_trim/iterations/v003/render-runs/run-001/baseboard-profile-detail.png).

For the French door, v010's paired four-row glazing, six hinge locations, and recessed casing read more clearly than v011's near-uniform brown finish. v010 still has repetitive narrow oak streaks. Its panes appear uniformly blue-gray in the actual room capture; because the area behind them is also a blank blue-gray exterior, that image cannot establish whether the glass transmits the intended garden view. Keep garden context as a separate room/environment asset, not door-mesh geometry. See the [approved r03 target](../../art/room_photo_french_door_production/visual_director/round-03/approved-target-r03.png), [v010 three-quarter](../../art/room_photo_french_door_production/iterations/v010/render-runs/run-001/asset-three-quarter.png), [v010 detail](../../art/room_photo_french_door_production/iterations/v010/render-runs/run-001/asset-detail.png), and [v011 three-quarter](../../art/room_photo_french_door_production/iterations/v011/render-runs/run-001/asset-three-quarter.png).

## Integrated scene and performance

The latest available 50-citizen room-scale showcase remains prototype-heavy: broad green cutaway walls, a plain floor, sparse low-detail furniture, and blue-gray exterior staging. It does not show an obvious whole-scene transformation. The capture is from [Batch 17](batch-17/room-photo-luna/room-scale.png); no production scene or geometry changed in this review.

The existing matched 50-citizen performance samples remain the relevant measurements because this review changed no runtime content: Batch 13 trim v002 was 2.940 / 3.444 ms median / p95 in the room view versus 2.975 / 3.534 ms baseline; Batch 16 French-door v010 was 3.005 / 3.657 ms versus v005 at 3.021 / 4.164 ms. These are single-session comparisons, not broad guarantees. See the [Batch 13 measurements](batch-13-room-shell/performance-baseline.json) and [Batch 16 measurements](batch-16/performance-v010.json).

## Disposition

- Trim r01 remains backlogged after three strategies; v002 is best current review, with cuboid runtime trim unchanged.
- French-door r03 remains backlogged after three strategies; v010 is best current review, with no production promotion.
- No candidate, target, gameplay geometry, RoomDefinition, or production registry entry changed. The canonical registry remains at 15 entries.
- Inventory remains 95 visible-art classes, 21 RoomDefinitions, and 318 room-object records. French-door notes now state that glazing transparency is unverified in the blank exterior capture.
- Next priority: faction visual identity, starting with an existing high-impact target episode that can improve a distinct structure or silhouette rather than another desk/citizen loop.
- The 27-test Art Factory suite and registered desk resolution passed after Batch 17; Batch 18 made no code or runtime changes.

Full-game visual migration remains incomplete.
