# POC 5 — Multi-Civilization Conflict

Clockwork Alpha and Verdant Alpha each start with twelve real founder citizens, 20 food,
30 water and zero construction stock. Their ordinary production societies share one
room, food cache, spilled water, furniture, salvage stages and traversal graph.

`room_conflict` derives from the accepted founder room. Its two generic start slots,
strategic frontier approach and larger 600-unit floor spill are authored room data.
The larger spill permits two independent settlements to recover reserves; it is one
source, not cloned stock per society. The original `room_poc47` stays unchanged.
`room_conflict_b` derives from Maker Loft geometry, removes the original completed
settlement objects for two founder starts and authors one visible seed packet and water
spill. Its different anchors exercise the same logic. The scenario file contains instance
and definition IDs plus anchor references, never physical coordinates.

After 120 seconds of ordinary production, each society sends a reachable real scout to
the frontier approach. Both must actually arrive. Their overlapping claims emit contact,
hostility and contest exactly once. The same bounded selection rule commits three
eligible citizens from each twelve-person roster. All physically arrive at distinct
stations before attacks begin. Equal 100 health, 10 damage, one-second attack interval
and six-inch range apply to both societies.

Targets are nearest hostile force member with global citizen-ID ties; attacks resolve
in citizen-ID order. The initial Clockwork roster has earlier IDs. This deterministic
initiative, route timing and initial needs are starting conditions, not civilization
combat bonuses. One casualty breaks morale before the remaining force is wiped out.
Morale is `1 - casualty_ratio*.65 - force_disadvantage*.20 - low_health*.15`, with a .70
retreat threshold. Survivors walk home. The winner waits for uncontested physical presence
and ten seconds of secure hold, captures the authoritative site, then returns to work.

The winner/loser and exact verified timing are published in the acceptance report.
Both continue earning settlement projects after battle. Death persists as a disabled
CitizenAgent with zero health. Ordinary production can later admit replacements using
its existing earned capabilities and reserve rules; the observer does not stage growth.

Limitations: one authored strategic site and one encounter per scenario; no diplomacy,
trade, treaties, pursuit, territorial taxes, asymmetric weapons or balanced initiative.
Combat does not target civilians. Forces stay on stable floor space; no fighting mid-vine
or mid-cable. Projected cosmetic bolts/pollen have no physics. The presenter remains
procedural, and far room views intentionally keep half-inch citizens tiny. Society task
boards and traversal project nodes remain scoped services; physical links, source state,
salvage and occupancy checks remain shared. General multi-instance HUD/tool selection
and automatic recurring wars remain future work.
