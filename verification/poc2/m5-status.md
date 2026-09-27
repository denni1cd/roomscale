# Milestone 5 — Visual Reconstruction Pass

Status: **PASS for recognizable room reconstruction; visual detail limits are recorded below.**

## Evidence

- Canonical candidate: `verification/poc2/candidates/primary/attempt-2/room_photo_luna.json` (unchanged from its AI repair and M4 validator pass).
- Final visual production command:

  ```powershell
  .\TEST_ROOM_SCALE.ps1 -Room verification\poc2\candidates\primary\attempt-2\room_photo_luna.json -TimeoutSeconds 1200 -CaptureVisuals -VisualPhases @('grapple-deployment','citizen-traversal','citizen-traversal-detail','elevated-surface-exploration','elevated-surface-exploration-detail') -VisualDirectory verification\poc2\canonical-primary-visuals-m5-final -LogPath verification\poc2\canonical-primary-m5-visual-final-detail.log
  ```

- Full production log: `verification/poc2/canonical-primary-m5-visual-final-detail.log`; it contains M2–M6 and M8 pass markers and five capture markers.
- Captures and notes: `verification/poc2/canonical-primary-visuals-m5-final/`.
- Whole-room initial view: `verification/poc2/canonical-primary-visuals-final/room_photo_luna-initial-room.png`.
- Photo-derived layout note: `verification/poc2/candidates/primary/attempt-1/reconstruction-note.md`.

## Review and limits

The whole-room initial view reviewed during M5 reads as the photographed room: deep green walls, warm wood crown/trim, large window/door openings, desk, cabinet, hammock area, and major furniture relationships are present. The candidate data includes the turquoise ceiling, but the saved open-top room view does not show the ceiling plane clearly, so its rendered color is not claimed as visually confirmed. The wide gameplay captures show the room shell and workstation from more than one stage. The final detail frames use a close camera from inside the room and hide the temporary overlay and world project sign only during capture.

The half-inch citizen remains small at 1280×720, and the cable is too thin to distinguish reliably in the detail screenshots. Do not use those images alone as proof of route continuity; the runtime M5 state/route assertions in the same production log provide that evidence. The reconstruction note discloses generic-shape compromises: flat ceiling, generic openings without pane patterns, simplified hammock/rockers/cabinet contents, and omitted small clutter/art detail. This is an approximate recognizable reconstruction, not a photo-realistic or dimensionally measured model.

The camera change only affects smoke-test framing. It does not enlarge cable geometry or alter gameplay state. The v3 and v4 capture runs are retained; v4 is the final diagonal-inside-room framing. See `m6-status.md` for separate gameplay evidence and `acceptance-matrix.md` for visual-criterion dispositions.
