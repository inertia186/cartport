# Oubliette

Oubliette is Cartport slot 03: a PICO-8-first, turn-by-turn first-person dungeon crawler.

## Design target

- Top strip: title, level, floor, and heading.
- Center: full-width first-person dungeon view with its own palette.
- Bottom: portrait, HP/XP, six inventory icons, messages, and compact control hints.
- Loop: explore a generated labyrinth, fight monsters, collect supplies, unlock an oubliette grate, descend, repeat.

## Controls

- Left/right: turn 90 degrees in place, spending one turn. Enemies may approach or attack after each rotation; turning around costs two turns.
- Up: move forward or bump/attack a monster.
- Down: step backward. An enemy behind you blocks retreat without taking damage; the attempt still spends a turn and enemies act.
- Z: inspect the grate underfoot; otherwise throw one blade notch at the first enemy straight ahead within four tiles. Walls stop targeting. Without notches, attack an adjacent enemy. When no attack occurs, inspect a grate in front or a chest underfoot/in front, pick up another item in front, or use a potion.
- X: open the actions menu. Up/down selects, Z acts, and X cancels. Opening, navigating, and canceling are free; selecting an action spends one turn. Movement and attacks are paused while the menu is open.
- Eat appears when you have food. It consumes one ration and heals up to `2 + level` HP when safe. At full health, it keeps the ration. An adjacent living enemy prevents eating; the turn is spent and enemies act, but no ration is consumed.
- Listen is always available. It spends a turn without eating, healing, or attacking, even when you carry food.
- Reaching a chest opens a prompt with **Use a key**, **Break the lock**, and **Leave**, using the same up/down, Z, and X controls. Arrival costs the normal movement turn; inspecting with Z, navigating, leaving, and canceling are free. Leaving keeps the chest available to inspect again.
- Use a key consumes one key and opens the chest, spending one turn. With no keys, the option explains that and spends nothing. Break the lock has a 10% success chance per attempt and never consumes a key. Every attempt, successful or failed, gives enemies one turn. Failure keeps the prompt open for another choice if the player survives; success gives the usual chest loot and closes it.
- Grates use the same key, lock-breaking, and leave choices. Stepping onto one costs a movement turn and opens the prompt; Z inspection is free. A successful unlock gives enemies on the current floor their turn before descent. Surviving players drop to the next floor and recover up to four HP. Fatal attempts cannot escape or recover by descending. Grates grant no chest loot.
- Dying on an Eat or Listen turn unlocks the joke death-screen achievement **Rest in Pieces**. Surviving that action and dying on a later turn does not count.
- An adjacent enemy outside the cell you face deals +1 damage after defense, including side and rear attacks. The message says "flanks" when this bonus applies. Turning toward an enemy protects you from that enemy's bonus on the ensuing enemy turn.

## Glow-up build

`pico8/oubliette/oubliette.p8` has been rebuilt as a clean, self-contained cart rather than an incremental patch over the first prototype.

The gameplay intent is unchanged: Oubliette is still a turn-by-turn first-person dungeon crawler about descending floor after floor, managing dwindling supplies, and surviving a hostile maze.

Current shape:

- Title, play, actions menu, and death/restart states.
- Connected room-and-passage generation with reserved stone, occasional loops, floor themes, and a locked grate at maximum walking distance.
- First-person viewport with projected masonry, a dark vanishing point, warm torch edges, iron floor grates, open arrival shafts, items, chests, and monsters.
- Turn loop where player actions resolve first, then monsters act when the action spends a turn.
- Movement, backward stepping, bump/attack, `Z` use, potion use, grate descent, and an `X` menu for eating and listening.
- Monster roster with floor-scaled selection, elite variants, line-of-sight wakeups, hunting, wandering, attacks, drops, and XP rewards.
- Slimes touching along an edge spend both of their turns combining. The survivor adds their remaining/max health and attack strength, keeps any elite status, and grows visibly with an `x2`, `x3`, etc. label. Wounds carry over. Each participant can combine only once per enemy turn and cannot also move or attack that turn; larger clusters take multiple turns to merge.
- Inventory and progression for HP, XP, level, gold, potions, keys, rations, attack, and defense.
- The blade inventory slot counts collected notches, starting at zero. Each adds +1 melee damage while held. A throw consumes exactly one notch and deals exactly 1 damage, without base attack, level, randomness, or elite modifiers. Bump attacks remain melee and do not consume notches. Throws spend one turn and use normal enemy death/reward handling; no target means no notch is spent.
- Locked chests with a choice to spend a key, risk repeated lock-breaking attempts, or leave. Opening one produces gold plus a useful stat/supply bump.
- Persistent title header and a compact bottom HUD with framed status bars, a six-cell icon inventory, and an authored sword-and-shield avatar; development telemetry and the minimap are intentionally omitted.
- Two message lines and compact arrow/`Z`/`X` hints replace the large D-pad.

Implementation stance:

- The map is a single tile grid: wall, floor, grate. Each floor records its arrival tile, including the first floor.
- Monsters and items are separate entity lists.
- Wall rendering traces each viewport column through the full tile grid to its first solid face. Room boundaries, exposed end faces, and receding sides therefore reflect the carved map rather than a stack of corridor planes. Actors and items are clipped against those wall distances; torches stay on their own wall faces.
- Grates and arrival shafts use 16×16 textures projected onto the floor and ceiling with native sprite strips. The grate has iron crossbars and a brass lock over a dark pit. The open shaft stays above the arrival tile as the player moves and turns; its wide rim remains partly visible directly overhead. Both openings draw before walls for occlusion and use the existing distance fade. They never enter the cached backdrop or consume gameplay RNG.
- The view is anchored to the player's current tile. An adjacent wall's near boundary is half a tile away. Actors and objects project at tile centers, and floor/ceiling coordinates use the same eye position and focal scale.
- The viewport spans columns 1–126 and rows 11–82. Its wider field of view retains the tuned focal scale and tile spacing; geometry and objects share the new center. Objects up to four cells to either side are considered for the wider view.
- Visual depth is compressed after the adjacent boundary: a wall one move away is half the adjacent wall's width, rather than one third. `view_z()` defines that artistic spacing for walls, actors, and objects; floor and ceiling mapping invert it. Movement, collision, and attack distances remain grid-based. Mid-distance stone retains its base color to avoid reading as a more distant wall.
- The native 128×128 sprite sheet holds actors/items in rows 0–31, legacy environment textures and decals in rows 32–47, the 16×16 avatar in rows 80–95, and UI frame pieces in rows 96–103.
- Rows 48–79 are reserved for generated masonry strips: four depth levels with cold and torch-lit variants. Wall columns sample these strips at their world intersection coordinates, keeping masonry continuous around corners. Plain walls no longer imply a usable gate.
- Medium and far wall textures blend between 1.5 and 3.5 tiles using the existing coverage patterns and native sprite transparency. At 2.5 tiles, half the medium texture is visible before the separate distance fade is applied. The same projected face is used for both textures, and torch-lit masonry fades with the detail rather than cutting off at the old boundary.
- Masonry retains chipped corners, short fractures, torch highlights, and texture at every depth. Nearby mortar uses dark stone tones; distant horizontal joints are interrupted instead of spanning each block, and the deepest band no longer blacks out most of every course. Row offsets vary the joint alignment. Moss forms muted green clusters and brick uses shorter courses.
- All six monsters have authored 16×16 sprites. Species have different projected sizes; walking enemies stand on the floor, while bats and wraiths float. Health bars appear on nearby or wounded monsters; elite outlines remain visible.
- Chests use a 16×16 sprite with a flat wooden lid, dark lid seam, iron straps, and a brass lock. Their larger projected size distinguishes them from loose pickups and preserves the box silhouette at a distance.
- Floor and ceiling retain the original masonry scale and converge toward the horizon. Their backdrop is cached in RAM `0x8000..0x9fff` and rebuilt with the masonry strips when the theme changes. This memory range is reserved for rendering.
- Walls, floor, and ceiling fade into black from two to eight tiles away using 16 stable coverage steps. Wall fading uses the actual ray distance, including distances beyond the four texture bands. The native fill pattern darkens existing pixels without changing the masonry; nearby detail, torches, and gameplay sprites remain readable.
- Screen shake, stone grain, and two-frame torch animation do not consume gameplay RNG.
- Native scanline palette switching (`0x5f5f`, `0x5f70..0x5f7f`) gives rows 11–82 the dungeon palette while the title strip and bottom HUD retain the UI palette. Stone gains a warm highlight and brown shadow tone; world blues and skin tones also have their own mappings. Both display palettes are applied after sprite blits and masonry blending reset them. The title and death overlays use shared colors so they can cross the palette boundary without a visible seam.
- A dirty-view flag limits the heavier masked redraw to state changes, shake frames, message changes, and the low-frequency torch tick.
- Turn resolution is intentionally explicit: player input -> action result -> monster phase -> death check. Every spent turn includes the monster phase, including rotations. Only one player action is accepted per update, so simultaneous inputs cannot act again after a fatal turn.
- Slimes combine opportunistically with an adjacent partner that has not acted yet, staying on the survivor's tile. Absorption grants no kill rewards. Defeating the survivor scales XP and gold by the number of combined slimes, with the usual single potion-drop chance. Projected size grows with the square root of that count, capped at twice normal size; health and attack continue adding beyond the visual cap.
- The action menu is a list of names, hints, and action functions assembled on opening. Chests and grates share the same lock choices and resolution, with hints distinguishing free choices from enemy turns. The compact overlay leaves HP and messages visible below it. Confirm/cancel keys must be released after menu transitions before they can act again.
- Browser and cartridge exports are generated from the `.p8` cart after validation.

## Visual verification

`visual-proof/grates/` shows the grate at three distances, its key/break prompt, arrivals on floors one and two, and the same ceiling shaft from three positions. `before/` retains the old stairs. Reproduce with `python3 scripts/render-oubliette.py --output game-specs/oubliette/visual-proof/grates --scenes grate-near grate-middle grate-far grate-menu grate-menu-break arrival-first arrival-second shaft-0 shaft-1 shaft-2`. Native checks cover key use, repeated breaking, leaving, enemy turns before descent, fatal unlocks, recovery order, shafts in every facing, wall occlusion, and redraw cost with both openings and an elite slime.

`visual-proof/chest-menu/` shows key use, no keys, lock breaking, leaving, and an enemy attack after a failed attempt, plus the regular action menu in its compact layout. Native checks cover arrival versus inspection costs, key consumption, the 10% success boundary, repeated enemy turns, rewards, held keys, death/restart, and preservation of the HUD below the prompt.

`visual-proof/chests/` compares the chest at one, two, and three tiles away; `before/` retains the old rounded sprite at the same positions. Reproduce the current views with `python3 scripts/render-oubliette.py --output game-specs/oubliette/visual-proof/chests --scenes chest-near chest-middle chest-far`.

`visual-proof/slime-combining/` shows a normal slime, sizes two through four, and a wounded pair after an actual merge. Native checks cover both list orders, spent turns, retained wounds/elite status, later attacks, repeated merging, invalid partners, rewards, visible growth, and viewport clipping. Reproduce these scenes with `python3 scripts/render-oubliette.py --output game-specs/oubliette/visual-proof/slime-combining --scenes slime slime-x2 slime-x3 slime-x4 slime-merge`. The fixed scenes use 46–49% of the warm redraw budget; combat balance still needs playtesting.

`visual-proof/actions/` includes the menu with food, Listen selected, no food, and full health. The menu uses colors shared by both screen palettes. Native input checks exercise free navigation/cancel, held keys, eating and listening with different supplies, enemy turns, healing limits, and fatal listening/restart.

`visual-proof/palette-hud/` records the full-width view, separate dungeon/UI palettes, all six monsters, title/death overlays, and large inventory/status counts with a two-line message. Native checks verify all 128 row selectors, final palette memory after sprite drawing, shared overlay colors, and empty bars. The fixed gameplay scenes use 34–49% of PICO-8's warm redraw budget. The switch uses PICO-8's [native secondary palette and row mask](https://www.lexaloffle.com/bbs/?pid=80804).

`visual-proof/detail-blend/` contains far, transition, and medium views of the same room, each one move apart; `before/` preserves the previous hard texture switch. Native checks sample the rendered wall at 17 distances, require partial detail halfway through, and bound the change between samples.

`visual-proof/distance-fade/` and its `before/` folder compare the distance shading on identical scenes, including a long hall. Native checks measure every fade level, verify that later drawing is unaffected, and retain the gameplay/RNG/frame/CPU checks. The fade uses PICO-8's [native fill patterns](https://www.lexaloffle.com/dl/docs/pico-8_manual.html#FILLP).

`visual-proof/restored-masonry/` records the current seam-focused adjustment with full stone detail restored. `visual-proof/soft-masonry/` retains the earlier experiment, which reduced repetition but flattened the dungeon too much in playtest feedback; its `before/` folder retains the original crypt, wide-room, and corner views.

Run `python3 scripts/check-oubliette.py` for native PICO-8 checks of initial facing, themes/facings, all six monsters at four depths, elite rendering, gameplay RNG preservation, viewport boundaries, avatar atlas preservation, and warm redraw CPU budget. Combat checks cover rotations, enemy approach, adjacent attacks, fatal turns, simultaneous inputs, facing damage with and without armor, blocked retreats, and forward attacks. It uses headless `-x` mode, splits rendering, geometry, mechanics, combat, menus, locks, openings, and slimes across temporary carts to stay within the token limit, and removes game callbacks so each process exits.

`visual-proof/before.png` and `visual-proof/after.png` retain the first pass comparison. `visual-proof/pass-2/` contains the next art pass: four dungeon themes, six encounters, a junction, stairs, an elite, and a bestiary sheet. Reproduce these with `python3 scripts/render-oubliette.py`; `--cart` and `--output` allow the same scenes to be rendered from another cart revision. These fixed scenes verify art and projection; they do not establish dungeon balance or end-to-end solvability.

`visual-proof/camera/` records the corrected eye position, including adjacent walls, walls one step away, and side passages beside the player versus one step ahead. Regenerate it with `python3 scripts/render-oubliette.py --output game-specs/oubliette/visual-proof/camera`. The native check also steps toward a wall in all four orientations and verifies that wall depth and side openings advance with the player.

`visual-proof/solid-walls/` records the full-grid renderer; its `before/` folder renders the same scenes with the earlier corridor renderer. Compare `room-corner.png` to see the previously missing wall end face. Native checks verify both faces of that corner, first-wall intersections against an independent ray march in all four orientations, and pixel-identical occlusion of hidden entities. Warm redraws in these fixed scenes use 26–39% of PICO-8's CPU budget.

## Architectural rules

Treat the dungeon as solid stone with deliberate spaces carved out of it.

- Each 19×19 floor selects six to eight chambers from a 3×3 arrangement of possible sites. Rectangular rooms are three or four tiles wide/deep, with at least two solid tiles between neighboring room footprints.
- A connected tree of selected neighboring rooms establishes the routes; one optional extra connection creates a loop. Unselected sites stay solid.
- Each connection is a straight, one-tile-wide passage between interior entrance positions. Passages cross the reserved stone rather than merging room footprints or cutting through room corners.
- Overlapping room carving and accidental wall remnants are removed. Thin partitions are not generated; a future hidden-door exception should be deliberate.
- The locked grate occupies a farthest reachable cell according to breadth-first walking distance, not coordinate distance from the start. The arrival shaft marks the starting cell on every floor.
- Loot and monsters occupy distinct floor cells outside the starting safety area. Placement stops when those cells are exhausted.

The room lattice is a bounded first implementation for the small map. Room shapes, occupied sites, selected connections, and loops vary; larger or less regular architecture can be introduced after playtesting this structure.

Run `python3 scripts/check-oubliette-layout.py` to verify connectivity, wall thickness, room spacing, grate distance, arrival shafts, spawn validity, and capacity handling across 64 seeded floors. Run `python3 scripts/render-oubliette.py --layouts --output game-specs/oubliette/visual-proof/architecture` for the top-down layout proofs. These checks establish navigability, not combat or supply balance.

## Image generation note

The requested `$imagegen` concept/interface pass and asset-sheet pass were generated first and copied into the project:

- `public/carts/oubliette-interface-concept.png`
- `public/carts/oubliette-asset-reference.png`

Full-size copies are also kept alongside them with `-full` suffixes for easier inspection.
