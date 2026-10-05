# Runtime measurement qualifications

Per-case wall times include observer overhead, engine startup and concurrent work.
They are not isolated production-engine benchmarks. Fixed-step milestone times
measure simulation behavior and are unaffected by wall-clock pause durations.

POS055/056/057 in the final campaign recorded7228.227/8677.375/1474.545 wall
seconds; neighboring cases normally take about20–33s for the same8-day duration.
The engine observer recorded the same pauses and all three completed4800 fixed
simulation seconds with every milestone and invariant intact.

Windows System events retained in [host-sleep-events.json](host-sleep-events.json)
confirm hibernation/resume and clock changes during this interval. Kernel-General
records15:57:55.620Z ->17:57:56.500Z, then17:58:06.255Z ->18:22:09.500Z. The
Power-Troubleshooter event also records sleep17:57:57.925Z and wake18:22:11.744Z.
These records explain the large external-time gaps; they do not establish an
engine performance defect. Raw durations stay in the primary machine summary.

Fresh exact saved-input replays for all three cases are retained under
`performance-replays/`. Their fingerprints must match the original final cases.
Representative eight-day runtime statistics exclude the three contaminated raw
samples and include these replay durations instead. All other original samples
remain included. This replacement is explicitly limited to runtime statistics;
pass counts, final states, milestone distributions and the final campaign evidence
continue to use the original full-campaign results.

No operating-system power setting was changed. Long-soak state is reviewed over
its entire simulation duration; the wall-clock allowance is3600s of waiting per
run and does not alter simulation progression. A suspended Windows process can
resume and finish with a larger observed wall duration, so wall time alone is not
a simulation health assertion.
