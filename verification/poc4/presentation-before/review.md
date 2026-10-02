# Presentation review — before Milestone 9

Inspected starting-settlement.png, salvage-stage-2.png and water-recovered.png from presentation-before/scenario-visuals/ (actual production state).

Functional chain passes, but this UI iteration is NOT accepted for AC-8/27/M9 readability:
- the resource status and strategy alert share vertical space;
- priority dropdowns retain their initial presentation values after programmatic high-level changes;
- the screenshot inspector is still on Desk while Chair is being salvaged;
- no normal-mode citizen need inspection is visible;
- cause/status text truncates before the authorization blocker.

Correct the HUD spacing, synchronize it from authoritative player state, expose normal citizen need inspection, and capture the actual selected salvage object and working/hauling citizens. Preserve the POC3 room/citizen renderer.
