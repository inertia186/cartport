# Pixel's Progress — Level Layout Doctrine

The main level doctrine for Pixel's Progress: concrete single-room geometry, route grammar, and hazard-placement rules for the N-family (Level 1) and Z-family (Level 2).

This note commits to a specific layout shape per level, a hazard placement doctrine grounded in where growth pressure would naturally pool, and a back-and-forth route structure inspired by Kid Icarus screen composition without copying any specific Kid Icarus room.

See also:
- `game-specs/pixels-progress/README.md`

## Why this pass exists

The earlier notes establish:
- Level 1 is the N-family room (three vertical chambers, top transfer, then
  bottom transfer).
- Level 2 is the Z-family room (three horizontal bands, right gap, then left
  gap).

What they do not yet pin down:
- where ledges actually live inside each chamber/band,
- where hazards belong as scenery rather than as floating punishment,
- how to bake heavy back-and-forth into a single-room PICO-8 screen.

This pass answers those three questions in a way a future cart edit can use
directly.

## Shared design guardrails

These apply to both levels and override anything cuter the layout might
suggest.

- **Full screen, single room, no scroll.** PICO-8 128x128 px. Treat it as a
  16x16 tile grid for design talk; the player still reads as one pixel.
- **Move set is sacred.** Move, single jump, gravity/fall, light air control.
  Nothing in either room may require wall jump, double jump, dash, ledge
  grab, or any unstated tech.
- **Smallness is the truth.** Geometry must look like a fair chamber for a
  1x1 body. Visual ambiguity is a bug.
- **Kid Icarus only as energy, never as copy.** Borrow the *feel* of a
  back-and-forth screen: a route that turns on itself, brief vertical
  switchbacks, and the sense that you are reading a single readable picture.
  Do not transcribe any specific Kid Icarus layout.
- **Hazards are scenery first.** Lava and sand are the first concrete hazard types. Lava falls, settles into the floor/platform surface where pooling reads as natural, and remains dangerous. Sand falls from random top-screen positions, is dangerous while falling, then becomes harmless stackable terrain after resting. Hazard contact does not deal HP damage; it adds a pixel and rotates the resulting body shape, pushing the player toward awkward traversal and fall-out risk. No unrelated floating damage motes in mid-air.
- **Back-and-forth is structural.** The level letter (N or Z) already
  reverses direction at room scale. This pass adds a *second* layer of
  switchback inside each chamber/band so the player visibly rewinds and
  re-commits multiple times.

### PICO-8 measurement assumptions

Used only to sanity-check the 1x1 viability of each layout. The cart can
re-tune later; the geometry below is sized so it stays viable across small
tuning changes.

- 1 tile = 8 px. Room = 16 x 16 tiles.
- Player hull = 1 px (treated as fitting any opening down to 2 px wide for
  comfortable side clearance).
- Assumed jump envelope: clears about **3 tiles vertical** at apex, about
  **3 tiles horizontal gap** with light air control. Anything tighter is
  flagged in the viability check.
- Assumed safe drop: any vertical distance, gravity is a free verb.

ASCII legend used in sketches:

```
.  empty space
#  solid block (floor / ceiling / wall / ledge)
|  thin vertical wall (chamber divider)
-  thin horizontal floor (band divider / ledge top)
~  lava / hot contamination surface (contact adds and rotates pixels)
^  corruption seam on a surface underlip (contact adds and rotates pixels)
s  resting sand terrain (harmless after landing)
@  player start
*  goal
o  transfer gap (kept empty in the divider, shown for emphasis)
```

Sketches are *topology* sketches. They are deliberately not pixel-perfect;
they are sized so the route shape and hazard doctrine read at a glance.


---

## Level family schema

This doctrine uses a lightweight grammar for designing rooms by structural family instead of inventing each room from scratch. The goal is not procedural generation in code; the goal is rule-shaped level thinking.

A level family is described by a small set of design axes:

- **Route letter** — the broad path impression (`N`, `Z`, `U`, etc.).
- **Chamber topology** — how many main areas exist and how they are separated.
- **Transfer rule** — where traversal between areas is allowed.
- **Hazard doctrine** — what danger is trying to do in this room.
- **Growth pressure** — how the room makes added pixels become costly.

Use this compact template when drafting a new room family:

```text
Family:
Route letter:
Topology:
Transfers:
Hazard doctrine:
Growth pressure:
Teaching goal:
Failure shape:
```

Useful family examples:

- `N` — up, over, down, over, up.
- `Z` — across, down-break, across.
- `U` — down into a basin, then back up.
- `I` — mostly vertical proof.
- `S` — alternating directional commitments.
- `M` — climb, dip, climb, dip, climb across several vertical strokes.

When designing a family, ask:

- Are the spaces columns, bands, pockets, islands, or something else?
- Are transfers top-only, bottom-only, side-only, or alternating?
- Is the route forgiving at transfers or intentionally tense?
- Does growth mainly threaten transfer points, the spaces themselves, or recovery after mistakes?
- What specifically becomes harder when the body changes: fitting, landing, timing, directional change, or recovery?

For now, use the schema as design scaffolding only. Do not build room generation code yet. Define one family at a time, then hand-author a room from that family.

## Level 1 — N-family room


### Family summary

```text
Family: N
Route letter: N
Topology: three vertical chambers
Transfers: left -> middle at the top, middle -> right at the bottom
Hazard doctrine: contact danger along the route, mostly testing whether the player can preserve smallness while traversing a known structure
Growth pressure: added pixels threaten route viability, transfer cleanliness, and final descent precision
Teaching goal: movement trust, route legibility, and the first meaning of "I got too big"
Failure shape: collapse of progress through loss of precision, awkward body shape, or out-of-bounds fall
```

### Room intent

Level 1 is the room where the player learns:
- the move set is exactly what it looks like,
- ledges mean what they appear to mean,
- staying small is what protects the route.

It must feel like a composed chamber, not a corridor. The player should be
able to look at it once, see the N, and start walking.

### Route beats

1. **Anchor.** Start bottom-left on the floor. The first jump is trivial and
   exists only to confirm jump height.
2. **Left ascent switchback.** Climb the left chamber via alternating ledges
   that force the player to face right, then left, then right, etc. Several
   reversals per chamber.
3. **Top transfer.** A gap at the top of the left/middle divider lets the
   player walk (not jump) into the middle chamber. Entering from above is
   the only allowed crossing.
4. **Middle descent switchback.** Drop through the middle chamber along
   alternating ledges. Falling cleanly is rewarded; flailing into the
   middle's growth pocket bloats the body and corrupts the rest of the
   route.
5. **Bottom transfer.** A gap at the bottom of the middle/right divider
   lets the player walk into the right chamber. Entering from below is the
   only allowed crossing.
6. **Right ascent switchback (the proof).** Climb the right chamber via a
   tighter switchback than the left. Goal sits top-right on a small
   landing.

### Proposed geometry / layout

Three vertical chambers, separated by two thin walls. Walls are full-height
except for one one-tile-wide notch each:
- **Left/middle divider** has its notch near the **top** (top transfer).
- **Middle/right divider** has its notch near the **bottom** (bottom
  transfer).

Inside each chamber, ledges alternate left-anchored and right-anchored so a
single jump cannot skip a tier; the player has to face-flip on each landing.

Topology sketch (16x16, schematic, not pixel-perfect):

```
0123456789012345
................   row 0   ceiling
......o........*   row 1   top transfer notch + goal landing
.###..|...##.###   row 2
....#.|.##....#.   row 3
.###..|....##.#.   row 4
.....#|##.....#.   row 5
.###..|...##.###   row 6
....#.|.##....#.   row 7
.###..|....##.#.   row 8
.....#|##.....#.   row 9
.###..|...##.###   row 10
....#.|.##....#.   row 11
.###..|....##.#.   row 12
.....#|##.....#.   row 13
.###~~|~~o~~~.#.   row 14   bottom transfer notch + contamination gutter
@###############   row 15   floor + start
```

Reading guide:
- `|` walls run from row 1 down to row 14, except for the `o` notches.
- The left chamber's switchback ledges (`###` and `#`) alternate sides on
  every other row so a player must face-flip per jump.
- The middle chamber is intentionally *thinner* (3 cols) so the descent is
  read as a fall path with intermediate ledges, not as a full sub-room.
- The right chamber's ledges sit closer to its outer wall to telegraph
  "this is the proof column."
- The whole bottom row of the middle and parts of the left are a hot
  growth channel along the floor (`~~~`); see hazard doctrine below.

### Switchback detail (left chamber, vertical slice)

```
 0 1 2 3 4
 . . . . .   apex of climb, rolls into top transfer
 # # # . .
 . . . . .
 . . . # #
 . . . . .
 # # # . .
 . . . . .
 . . . # #
 . . . . .
 # # # . .   each ledge is 2-3 tiles wide
 . . . . .
 . . . # #   gap between tiers is about 2-3 rows
 ~ ~ ~ ~ ~   growth-pressure gutter at floor level
 @ . . . .   start
```

The cadence is: stand on a left-anchored ledge facing right, jump to a
right-anchored ledge above, turn around, jump to a left-anchored ledge above
that, and so on. The player physically reverses direction every tier.

### Lava / hazard placement doctrine (Level 1)

Lava is the current persistent surface hazard. It should begin as a falling droplet, land on the first floor/platform/solid surface it touches, and become that local floor surface rather than sitting on top of it. It never deals health damage; contact adds a pixel and rotates the resulting body shape, which corrupts the route and eventually makes the player too awkward for the clean line. Place lava only where pooling reads as spatially honest — gutters, basins, underlips, lower pockets, and route channels.

- **Floor channel along the left chamber and under the middle chamber.**
  A contamination gutter below the lowest left-chamber ledge and across
  the bottom of the middle chamber. Flailing falls land in pixel-adding
  zones without blocking the legitimate ground route, which threads along
  the very bottom row on the way into the start.
- **Underlip of the top transfer.** A short corruption seam on the
  underside of the top transfer ledge so a sloppy approach to the notch
  eats a contact and gains pixels. This is *not* a floating hazard; it is
  geometry attached to a ceiling.
- **Right chamber base pocket.** A small basin two rows above the floor in
  the right chamber. If the player botches the final descent and falls
  inside the right chamber, they land in the growth pocket, not on a
  clean floor. This is the "you are getting too big for this line"
  reminder.

What is intentionally *not* used in Level 1:
- airborne / floating contamination motes,
- moving hazards,
- growth zones in the start row near the player anchor,
- growth zones that block the only legal route through a transfer notch.

### Why this layout creates back-and-forth

- **Room scale.** The N route already forces three direction changes:
  up-left, across-and-down through middle, up-right. That is the macro
  back-and-forth.
- **Chamber scale.** Each ascent chamber is a switchback ladder. The
  player faces right to launch, then left to launch, then right again,
  several times per chamber. That is the micro back-and-forth.
- **Recovery scale.** Because the middle descent has alternating ledges,
  a missed landing usually drops the player to a *lower* ledge, not all
  the way to the bottom. The player frequently has to climb a row,
  reverse, climb a row, reverse, instead of restarting. That is the
  recovery back-and-forth, and it is where Kid Icarus screen energy
  actually shows up.

### 1x1 viability check (Level 1)

Walking only this layout with the canonical move set:

- **Start to first ledge.** One jump up to a 2-3 tile wide ledge two rows
  above the floor. Within the assumed 3-tile vertical envelope. OK.
- **Switchback step.** Each tier shifts the anchored side and rises about
  2 rows. A single jump with light air control covers it. OK.
- **Top transfer.** Player walks horizontally through the top notch; no
  jump required at the transfer itself. OK.
- **Middle descent.** Pure gravity, with optional lateral nudge to land on
  the next ledge. No upward jump needed. OK.
- **Bottom transfer.** Walking step through the bottom notch. OK.
- **Right ascent.** Same envelope as the left ascent, but ledges sit
  closer to the right wall, so air control matters more. Still inside the
  assumed envelope. OK.
- **No tech required.** No wall jump, no double jump, no dash, no ledge
  grab, no crouch, no precise mid-air reversal beyond light air control.
  OK.
- **Failure modes are legible.** Falls land in the contamination channel
  or in the right basin, both visibly sunken / hot. The player reads the
  reason for losing precision (extra pixels, awkward shape) immediately;
  failure is route corruption, not death.

If the cart's tuned jump turns out to be smaller than assumed, the
mitigation is simply to drop tier spacing from about 2 rows to 1 row
across the board; the design topology and growth-pressure doctrine do
not change.

---

## Level 2 — Z-family room


### Family summary

Level 2 should keep the same movement verbs while changing what the route asks the player to understand. Its job is to prove:

- directional commitment,
- route reversal across height bands,
- growth pressure during traverse and breakpoints, not only during ascent.

Family summary:

```text
Family: Z
Route letter: Z
Topology: upper band, break/drop band, lower band
Transfers: right-side gap first, then left-side gap
Hazard doctrine: pressure on traverse commitment and directional breaks
Growth pressure: added pixels make line changes, landing cleanup, and lower-route comfort worse
Teaching goal: growth should feel costly during route reversal, not just during vertical climb
Failure shape: the player gets too large before or during the break and the lower traverse becomes awkward or unsafe
```

This gives Level 2 the same structural dignity as Level 1, just rotated. The new truth to prove is the room family, not feature expansion.

### Room intent

Level 2 is the room where the player learns:
- growth pressure still bites when the route is mostly horizontal,
- direction reversal is its own skill,
- the game has a family of rooms, not one room.

It should feel like a rotated cousin of Level 1, not a new game.

### Route beats

1. **Upper-left anchor.** Start at the upper-left of the top band. The
   player can immediately tell they are higher than they were in Level 1.
2. **Top traverse with mini-reversals.** Move right across the top band
   past short bumps and dips that force tiny lateral switchbacks.
3. **Right-side break.** Reach the right end of the top band and drop
   through the right-side gap into the middle band.
4. **Middle reversal.** Move *leftward* across the middle band. This is
   the heart of the Z: the room asks the player to undo the direction it
   just rewarded.
5. **Left-side break.** Reach the left end of the middle band and drop
   through the left-side gap into the bottom band.
6. **Bottom finish traverse.** Move *rightward* again, threading a
   tighter, more cluttered bottom band, to a goal in the lower-right.

### Proposed geometry / layout

Three horizontal bands, separated by two thin floor/ceiling barriers
(`---`). Each barrier is full-width except for one one-tile-wide gap:
- **Top/middle barrier** has its gap on the **right**.
- **Middle/bottom barrier** has its gap on the **left**.

Inside each band, the floor is not flat. Each band has small bumps and
dips that force the player to jump or step around them, creating mini
back-and-forth even within a single direction of travel.

Topology sketch (16x16, schematic, not pixel-perfect):

```
0123456789012345
@..............    row 0   start, upper-left
.....##........    row 1   top band: bumps to step over
...##.....##...    row 2
.##.........##.    row 3
---------------o   row 4   top/middle barrier, right gap
...............    row 5   middle band entry, moving left
......##.......    row 6
..##......##...    row 7
............##.    row 8
o---------------   row 9   middle/bottom barrier, left gap
.~..............   row 10  bottom band entry, dropping in on the left
.~~..##.....##.    row 11  bumps over basins
.~~~##....##...    row 12
.~~~.....##....    row 13
.~~~~~~..######    row 14  goal landing on the right
##############*    row 15  floor + goal
```

Reading guide:
- `o` shows where the inter-band barriers leave a single-tile gap. The
  gap on row 4 sits at the rightmost column; the gap on row 9 sits at
  the leftmost column.
- The bumps in each band are intentionally short (1-2 tiles tall) so a
  1x1 player can hop them with the canonical jump.
- The bottom band runs a contamination trench along the left wall and
  under the early floor — that is where growth pressure naturally pools
  after a drop-in from the left-side gap.
- The goal sits on a small landing at the right of the bottom band.

### Mini-reversal detail (top band)

```
 0 1 2 3 4 5 6 7 8 9
 @ . . . . . . . . .
 . . . . . # # . . .
 . . . # # . . . . #
 # # . . . . . . # .
```

Each `##` bump is short enough to hop. But to *get on top* of a bump
without overshooting, the player typically lands, takes a step back,
re-launches with cleaner spacing, then continues. That is the mini
back-and-forth — the same energy that makes Kid Icarus screens feel busy
without adding new verbs.

### Lava / hazard placement doctrine (Level 2)

Level 2 is not just more Level 1. It should prove directional commitment, route reversal across height bands, and growth pressure during traverse/breakpoints rather than only during ascent. Lava in Level 2 belongs in three spatially honest places. As in Level 1, contact adds/rotates pixels rather than draining HP — the cost is shape, precision, fall-out risk, and route viability.

- **Bottom-band trench along the left wall.** The leftmost columns of the
  bottom band form a natural pit: the player drops in there and the floor
  sinks. Contamination settles in the sunken pocket. Walking right out
  of the pit requires a careful jump up and across, which is exactly the
  posture-change the band is supposed to test; lingering means picking up
  pixels you did not want.
- **Basins under top-band bumps.** Each bump in the top band casts a
  small dip on its downhill side. A botched hop drops the player into
  the dip, where a short corruption seam lives. This is a seam attached
  to geometry, not a floating mote.
- **Right-gap underlip.** The single-tile drop point at the right end of
  the top/middle barrier has a hot underlip. Wandering off the lip
  cleanly is fine; clipping the corner on the way down adds pixels. The
  zone exists because that is where pooling would naturally cling to a
  ledge edge.


### Sand doctrine

Sand is a separate hazard family from lava. Falling sand is dangerous: contact adds a pixel and rotates the player shape. Once a grain lands, it becomes harmless terrain. Resting sand stacks vertically as blocky one-pixel terrain; it does not roll down slopes or simulate granular hills. This keeps sand as escalating level pressure rather than a tiny physics-engine project.

Looping through the final level increases sand frequency. The intent is that repeated loops gradually fill the playfield with blocky sand terrain, changing traversal without requiring new player verbs.

What is intentionally *not* used in Level 2:
- floating mid-air contamination between bands,
- growth zones stacked on the goal landing,
- growth zones inside the transfer gap itself; the gap stays clean so the
  break is a *commitment* test, not a *contact* test.

### Why this layout creates back-and-forth

- **Room scale.** The Z route reverses direction twice: right across the
  top, left across the middle, right across the bottom. The player
  walks the room in three opposite-handed strokes.
- **Band scale.** Each band has at least one bump-dip-bump pattern, so
  the player frequently hops, lands short, takes a step back, and
  re-launches. That is the Kid Icarus screen rhythm in miniature.
- **Recovery scale.** Missing the right gap drops the player back onto
  the top band, often a few tiles short of the gap. They have to
  reverse, walk back, and re-commit. Same idea on the left gap. The
  recovery itself is back-and-forth, not a restart.
- **Growth scale.** Once the player has accumulated pixels, the bumps
  become harder to clear cleanly and the trench in the bottom band
  becomes harder to escape. Growth pressure manifests as *more*
  back-and-forth, because the body now needs more re-tries on the same
  geometry.

### 1x1 viability check (Level 2)

Walking only this layout with the canonical move set:

- **Start to first bump.** Walk right; hop a 1-2 tile bump. Inside the
  assumed jump envelope. OK.
- **Top traverse.** Each bump is hoppable; each dip is shallow enough to
  walk out of with a single jump. OK.
- **Right-side break.** Player walks off the right edge of the top band;
  pure gravity drop into the middle band. No jump required at the
  transfer itself. OK.
- **Middle traverse.** Same bump-and-step pattern as the top band, mirror
  direction. OK.
- **Left-side break.** Player walks off the left edge of the middle band
  through the left gap; pure gravity drop into the bottom band. OK.
- **Bottom traverse.** The first motion after dropping in is a single
  jump up out of the contamination pit onto the bottom-band shelf, then
  a bump-and-step rightward to the goal. The escape jump is sized to fit
  the assumed 3-tile vertical envelope. Linger in the pit and you leave
  it carrying extra pixels. OK.
- **No tech required.** No wall jump, no double jump, no dash, no ledge
  grab, no crouch. Light air control is enough to nudge over a bump and
  land cleanly. OK.
- **Failure modes are legible.** Missed gaps drop you back onto the
  band you just left; bad bumps drop you into a visible basin; bad
  drop-in alignment puts you in the trench. Each visible sink reads as
  "you will leave here bigger," not "you took damage." The player can
  always read what went wrong.

If the cart's tuned jump turns out to be shorter than assumed, the
escape jump out of the bottom-left trench is the most sensitive point.
Mitigation is to raise the trench's exit shelf by one row, leaving the
rest of the geometry — and the growth-pressure doctrine — untouched.

---

## Level 3 — M-family room


### Family summary

```text
Family: M
Route letter: M
Topology: four vertical strokes divided by alternating high and low transfers
Transfers: high cap, low trough, high cap, then final descent to lower-right goal
Hazard doctrine: danger lives in troughs, high underlips, and recovery pockets where sloppy crest/valley transitions naturally pool
Growth pressure: added/rotated pixels make repeated narrow handoffs harder, but can sometimes be exploited for risky reach
Teaching goal: route rhythm across multiple crests and valleys; growth is both liability and temptation
Failure shape: overgrown body falls out during a trough escape, clips a hot underlip, or loses precision on the final descent
```

### Room intent

Level 3 adds the M-family: a repeated up/down structure made from four vertical strokes. It should feel like the player is writing an M with their route: climb, drop, climb, drop, then descend into the lower-right goal. Unlike Level 1's three chambers or Level 2's horizontal bands, the M-family tests whether the player can survive several crest/valley transitions in sequence.

### Route beats

1. **Left stroke climb.** Start bottom-left and climb a familiar switchback. This is the confidence beat.
2. **First high transfer.** Cross a high cap through the first divider. The underlip is dangerous if the player clips it while awkwardly shaped.
3. **First valley descent.** Descend the second stroke toward a low trough. The trough is where lava and sand pressure can accumulate.
4. **Middle climb.** Escape the trough and climb the third stroke. This is the main M-family proof: recovery from a low pocket into another climb without new verbs.
5. **Second high transfer.** Cross the second crest. The player is now more likely to carry extra pixels, so a formerly easy handoff becomes tense.
6. **Final stroke.** Traverse the last stroke into the goal at the upper-right.

### Lava / hazard placement doctrine (Level 3)

Lava belongs where the M shape creates natural trouble:

- **Trough bases.** The low points between strokes are natural basins. A clean player can escape, but lingering or entering at a bad angle creates hit pressure.
- **High underlips.** The top transfer caps can have hot seams underneath them. The route itself stays passable; the punishment is for clipping the crest while overgrown or misaligned.
- **Final descent base pocket.** The last climb should have a low pocket that punishes missed final attempts without making the goal landing itself dirty.

Sand keeps the same global doctrine: falling sand is dangerous, resting sand becomes harmless blocky terrain. In M-family rooms, resting sand can either help bridge troughs or create awkward clutter before a climb, which fits the family without adding a new rule.

### 1x1 viability check (Level 3)

- The first climb mirrors already-tested N-family ledge spacing. OK.
- The high transfers are platform/cap handoffs, not new movement verbs. OK.
- The trough escapes must remain within the current single-jump envelope. If they fail, lower the exit ledge or raise the trough by one row before touching movement constants.
- The lower-right goal should remain reachable by the 1x1 player without requiring hit-assisted growth. Growth-assisted reach is allowed as risky emergent play, but not as the intended route.

---

## What to actually build first

Suggested build order, to keep this pass cheap:

1. Block out Level 1's wall and ledge geometry without hazards. Verify the
   N route is walkable end to end with the current jump.
2. Add the contamination channel along the left/middle floor and the
   right basin. Verify the growth-pressure zones read as scenery, not as
   floating punishment.
3. Block out Level 2's three bands with the alternating gaps. Verify the
   Z route is walkable end to end with the current jump.
4. Add the bottom-left trench, the bump-dip seams, and the right-gap
   underlip. Verify the same readability check: pooling reads as
   spatial, contact reads as pixels gained.
5. Block out Level 3's M-family strokes and alternating crest/trough handoffs. Verify the M route is walkable end to end before tuning hazards.
6. Only then revisit growth tuning, since the room layouts are now stable
   enough to make growth a meaningful pressure source.

## Open questions left for a later pass

- Should the left and right ascent chambers in Level 1 be exactly mirror
  images, or should the right chamber be one tier taller as an honest
  difficulty step?
- Should the top band of Level 2 be flat with one bump cluster, or
  evenly bumpy across its full width?
- Should the right-gap drop in Level 2 be a clean fall, or a one-tile
  overhang the player has to step off rather than walk off?
- At what accumulated-pixel threshold does the Level 2 bottom-left
  trench stop being escapable, and is that the desired "I got too big"
  beat for this family?

These are intentionally left open. This pass's job is to commit to room
shape and hazard doctrine, not to finalize growth math.
