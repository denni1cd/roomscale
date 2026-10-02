# Milestones 0–2 evidence

M0 PASS: unchanged-source fast and POC3 visual checks, full Room A, Room B and accepted primary photo attempt 7 production smoke scenarios. Logs: baseline/fast.log, baseline/visuals/, baseline/cross-room/step-01-room_a.log, baseline/room-b.log, baseline/photo-room.log. Additional A/B/A sequence continues in baseline/cross-room/. Fresh launch.png inspected against retained POC3 final-polish settlement imagery. No renderer rewrite.

M1 PASS: m1-final.log drives normal production citizen/task/need logic for 2 simulated days, fifty citizens, 200 meals, 300 drinks, 138 rests, all 50 participating. Critical need effort penalty and finite shelter/rest tested. First run failed bounded task lifecycle; m1-attempt1.log retained. Corrected shared coordinator to avoid accumulating unclaimed routine jobs during self-care.

M2: economy uses exclusive reserved/in-transit/delivered states and consumed totals, population-based forecasts (2 food and 3 water/citizen/day), cancellation release, conservation audit. Normal HUD displays authoritative state; m2-final.log records verification result.

One simulation day is 600 simulation seconds. Tests invoke the same fixed production step as interactive play, without teleportation or resource grants.
