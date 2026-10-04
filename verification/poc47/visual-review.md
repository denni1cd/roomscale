# Founder visual review

The 24 full-scenario PNGs in `final-render/scenario-visuals/` were inspected as
contact sheets, with full-size checks of startup and completed primitive structures.
Every image is a real production viewport; JSON sidecars retain simulation state.
The live run captures the unmodified automatic camera at normal wall-clock speed.
All eight fresh `final-live-1x/` images were also inspected: founder arrival,
salvage, actual carried material, builder work, completed shelter and the next
depot site. The fresh run measured 185.4 simulation seconds in 185.611 wall seconds.

| Evidence | Review |
| --- | --- |
| `five-founders-empty-settlement.png` | Five separate citizens, five portable packs, 5/0 shelter, two-day provisions, zero wood/metal and 1x. No settlement buildings. |
| `first-salvage.png`, `physical-hauling.png` | Actual work at a room object's edge and ordinary carried parcels. Half-inch figures are visible in close views. |
| `shelter-foundation/frame/shell/complete.png` | Planned outline, supplied structure, progressive enclosure and persistent roof. Capacity reads zero before completion and five after. |
| `depot-foundation/frame/shell/complete.png` | Construction progresses beside the unchanged cache apron; completion card identifies permanent storage. |
| `workshop-foundation/frame/shell/complete.png` | Existing citizen-scale workshop geometry progresses with actual work. Completion enables advanced construction. |
| `housing-foundation/frame/shell/complete.png` | Permanent housing uses preserved POC46 proportions and the real material/work card. |
| `first-new-citizen.png` | Population six and singular NEW CITIZEN wording; actual new node shown in the settlement. |
| `grapple-construction.png`, `physical-climbing.png` | Actual grapple project and a citizen partway up its cable; preserved legacy world label can dominate very close framing. |
| `elevated-expansion.png` | The elevated supply and NEW TERRITORY REACHED event correspond to real collection. |
| `established-settlement.png` | Twelve citizens, fifteen shelter places, four persistent completed buildings and the deployed grapple in the transformed room. |

The compact status/project/event panels leave the central subject clear. Text remains
readable; F3 diagnostics and edge layout also pass the 1080p/1440p fast presentation
checks. Every replay screenshot shows 1x because replay calls ordinary fixed ticks,
not a changed gameplay speed. These accelerated captures alone do not prove wall-clock
pacing; `final-live-1x/` supplies that separate evidence.

## Presentation limits

Primitive buildings are intentionally simple low wooden structures. Roofs obscure
their small interior details from above. Citizens remain tiny in wide room views;
the director alternates context and real worker close-ups. Some event cards describe
a just-completed event while a subsequent project card shows current work; their day
stamp and wording preserve that distinction. No broad art rewrite was attempted.
