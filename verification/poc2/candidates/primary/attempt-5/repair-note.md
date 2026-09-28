# Candidate repair — attempt 5

Attempt 4 moved the depot far enough from the derived construction site, but its pickup point `[50, 0, -52]` fell inside the hammock's blocking footprint (`x=-59..59`, `z=-66..-32`). The full gameplay run reached two construction stages and then remained one mechanical part short.

This repair moves only the simulation depot landmark and pickup point to `[45, 0, -20]`, on open floor between the hammock and desk. It does not move or resize photographed room objects. The failed M2 log is preserved at `../attempt-4/production-smoke-failure.log`.
