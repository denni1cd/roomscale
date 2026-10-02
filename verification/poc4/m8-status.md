# Automated verification gate

Final authoritative gameplay batch: release/summary.json, 8/8 PASS (fast, contract, five consecutive complete scenarios each with seven days after recovery, and thirty days after recovery). Recovery 741 seconds in every final run. Thirty-day bounds: history500, tickets25, bundles10, longest active task 249.5 seconds. Every active salvage worker is checked within0.3 inches of physical object edge. The full batch was rerun after the edge-access correction. Subsequent UI-only edits passed final-fast/ and rendered final-evidence/ seven-day scenario. See final-report.md and acceptance.md; earlier batches below remain historical evidence.

Initial full batch final/summary.json: fast tests, five fresh complete scenarios with seven days after recovery each, and thirty additional days all PASS. Thirty-day run: maximum history 500, tickets 24, bundles 10; longest active task  257.5 simulation seconds; maximum movement per 0.1-second tick 0.650004 inches (walking limit 0.65 plus floating-point tolerance).

Subsequent architecture audit:
- AC-29/30: partial frame narrows its navigation footprint before depletion.
- AC-18: validate finite source extraction points against declared floor/surface geometry; reject unsupported contents, invalid material, empty-yield stages and invalid construction flag.
- AC-11: validate construction ticket resource/amount/owner and retain exported-to-dropped-bundle accounting.
- AC-28: derive selected Reach target/site from the requested surface, including sources that differ from initial room target.
- AC-5/6: limit rest slots by shelter capacity and clear cancelled rest ownership.

Run audited/ as the authoritative full batch after these changes. The alternate-surface proof in alternate-surface.log/json moves the water source to a new SUPPLY_SURFACE on the side table while preserving the original room target; the same production systems complete the entire chain ( 629 seconds), proving source-driven construction rather than a hidden initial-target dependency.

Regression evidence is under regression/; no gameplay implementation substitutes for these actual runs. Presentation-before/review.md records issues found by visual inspection and requires correction in Milestone 9.
