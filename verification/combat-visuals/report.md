# Combat presentation improvement

Branch: `codex/combat-visuals`, based on `b2916d969b7daa0b3af049329b5fccab2b0322fa`.

The original weapons were small boxes and attacks were long thin lines. Combat now uses a detailed brass receiver/barrel/winding gear for Clockwork and a leaf-limbed thorn bow for Verdant. Weapons mount to the figure so their barrels point toward the target instead of inheriting the raised arm's rotation. Holding combatants use a two-arm aiming pose; real attack callbacks initiate cosmetic recoil.

Presentation-only effects now use moving bolts/seeds, short colored trails, muzzle flashes, Clockwork steam puffs, Verdant arcing pollen, and impact bursts. Transient effects expire after half a render second. Cosmetic travel does not delay or resolve damage; production CombatSystem remains authoritative.

Gold/green ground rings distinguish committed forces. Health bars reflect actual citizen health and disappear after death or return to ordinary duty. The combat HUD exposes the secure-territory objective, committed force sizes, and losses.

These remain procedural stylized citizens; this pass improves readability and effects, rather than replacing the game's overall character art. No collision, navigation, casualty, morale, pressure, attack range, force size or simulation timing rules were changed.

Verification:

- Scarcity/pressure: PASS (`pressure-receipt.log`).
- Canonical deterministic conflict: PASS, identical 3/3 (`repeatability-receipt.log`).
- Second conflict room: PASS (`second-room-receipt.log`).
- Fast: PASS (`fast-receipt.log`).
- Final offscreen real-renderer conflict: PASS, no engine errors/warnings (`final/run.log`).
- Final rendered run compared directly to the original main result: identical contact/commit/capture ticks, force sizes, attacks, casualties, morale, retreating side, winner, returned counts and living populations.
- `git diff --check`: PASS.

The graphical observer keeps the window offscreen and non-focusable so the user's desktop work is not interrupted. Screenshots are actual Godot captures, not generated mockups:

- [Battle overview](final/04-battle.png)
- [Clockwork weapon](final/04-clockwork_alpha-weapon.png)
- [Verdant weapon](final/04-verdant_alpha-weapon.png)

The standard conflict observer takes stills while advancing the production fixed clock. These verify appearance but do not represent a complete realtime animation acceptance review. The earlier original visual-validation gate remains separate.
