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
salvage and occupancy checks remain shared. Interactive selection of another society and automatic recurring wars remain future work.

## Multi-party extension

`room_conflict_c` adds a third generic start slot and a finite elevated water cup to
Maker Loft. `scenarios/three_party_conflict.json` composes Clockwork, Verdant and
Scavenger through data. Startup validates every participant, namespace, definition,
slot and complete non-overlapping roster before replacing the scene's startup actors.
The number of participants is determined by scenario data and available legal stations.

Every living society must physically establish its claim before battle commitment.
Contact and scarcity are evaluated for every bilateral relation. The greatest pressure
sets the encounter policy, while only endpoints of hostile relations join its forces.
A comfortable third claimant neither blocks a scarce pair's war nor becomes its enemy.
Target selection and morale consider only living, non-retreated hostile forces.

Multi-party stations use deterministic radial rows and ordinary navigation. Fighters
outside attack range close distance through that navigation; damage never teleports
actors. Each side withdraws independently. The first retreat in a three-party battle
leaves two contenders fighting and chooses no winner. Only one remaining force can
secure the site; all rivals must physically withdraw, and a living peaceful claimant's
unresolved claim prevents exclusive military capture. Remaining non-hostile forces
stand down instead of inventing a winner. Ten seconds of uninterrupted physical hold
are still required, and survivors return to ordinary production jobs.

Two-party station placement and shared damage/initiative rules are preserved. The
shared HUD lists every society's population, forces and losses; optional `combat_style`
selects industrial or organic presentation through data. Scavenger currently reuses
industrial meshes with its own palette and rope solution; it has no combat bonus.

```powershell
./RUN_ROOM_SCALE_CONFLICT.ps1 -Room room_conflict_c -Scenario three_party_conflict
# The same world can also research and construct shared access after conflict:
./RUN_ROOM_SCALE_CONFLICT.ps1 -Room room_conflict_c -Scenario three_party_conflict -Innovation
```

The extension still uses one authored contested site and one resolved encounter,
with a cooldown. Trade, treaties, coalition ownership, recurrent campaigns, civilian
combat and fighting on elevated links are outside this milestone.

## Mixed-intensity policy (POC 5.3 stabilization)

Commitment follows Model A: each society uses the strongest bilateral hostility in
which it personally participates. A survival pair beside a limited pair therefore
produces survival/survival/limited policies, not a universal survival war. Per-side
force fraction/minimum/maximum, retreat permission and threshold are captured at
commitment; the encounter's greatest intensity is only a summary label. Force formation
validates every side before any commitment. No mid-battle automatic conscription occurs.
Ongoing bilateral relations still govern targets and whether fighting has a live cause.

`pair_benefits` optionally scopes a site's contested benefits to canonical instance-pair
keys; schema validation rejects unknown/noncanonical pairs. This permits legitimate
mixed causes rather than injecting intensities. The mixed fixture has severe space
pressure for Clockwork/Verdant, moderate shared pressure for Verdant/Scavenger and no
contested benefit between Clockwork/Scavenger. Its authored founder counts are 4/12/8:
the first two commit their entire own rosters, while Scavenger commits two citizens and
retreats with a survivor. The survival side's elimination is terminal, not an ordinary
morale retreat. Different pair benefits describe contested relevance, not treaty logic.

Participants, startup rosters, fixed society steps, policy folding and target initiative
use stable IDs. Reversing participant/runtime order is tested against the complete
physical engagement fingerprint. A surviving peaceful claimant prevents exclusive
capture even if it previously fought a different rival in the engagement.

The three-society combined innovation room now includes a visible 24-unit finite scrap
tray. Its stock comes from two real salvage stages, not depot grants. That extra authored
supply funds the larger new structure after three ordinary settlements. This does not
prove a global affordability allocator: prototypes can wait when legitimate finite
materials are exhausted, as ordinary settlement projects can.
