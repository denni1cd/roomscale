# Candidate repair — attempt 4

Attempt 3 passed structural and runtime-navigation validation, but the full production smoke test stopped in M2 because its depot pickup was too close to the derived construction site for the harness's minimum meaningful delivery route.

This repair moves only the simulation depot landmark and pickup point to the clear northeast floor area at `[50, 0, -52]`. It does not move or resize photographed room objects. The failed smoke log remains at `../attempt-3/production-smoke-failure.log`; attempt 4 has a new candidate and will receive its own validator and production logs.
