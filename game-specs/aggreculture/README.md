# Aggreculture

Aggreculture is a top-down action-farming game for PICO-8. It borrows the
immediate movement, readable room composition, and directional tool use of an
early Zelda game, then points those verbs at a tiny, unruly farm.

## Core promise

Grow a harvest while defending it from hungry blights. Farming is the quest,
not a menu between quests.

## First playable loop

1. Begin on the seed selector and choose a four-digit world seed.
2. Enter the center homestead of a generated 3×3 overworld.
3. Explore for clear ground or use one of the homestead's starting plots.
4. Tap `Z` until `X` is assigned to Hoe, then work wild terrain into a plot.
5. Tap `Z` to assign Farm to `X`, then till, plant, and harvest with `X`.
6. Crops grow in real time through three visible stages, even while traveling.
7. Blights enter the homestead and head for planted crops.
8. Press `X` toward a blight to drive it off.
9. Harvest the generated crop quota to finish the morning.

## Seed selector

The seed selector is always the first screen. Its four-digit value seeds the
run's deterministic generation rather than choosing a crop variety. Reusing a
seed recreates the same starting overworld setup.

The first generated elements are:

- connections between nine adjacent overworld screens
- meadow, grove, and stonewild screen biomes
- harvest goal and starting seed-bag size
- crop growth rate and color
- blight movement speed and wave timing
- positions and types of overworld rocks and trees
- positions of collectible wild-seed caches

Left/right changes the value by one, up/down changes it by one hundred, `Z`
generates the overworld, and `X` chooses a random value. After a win, the player
returns to the selector before generating another morning.

## Overworld generation rules

The world is a 3×3 screen grid with the farm fixed at the center. Generation
first connects every screen to a path that leads back toward the farm. The
world seed then adds optional links, producing loops and alternate routes
without creating unreachable screens.

Each non-farm screen receives a seeded biome, rocks or trees, and wild-seed
caches. Exit corridors remain clear during object placement. If an edge has a
connection and nothing blocks its corridor, walking through it moves the player
to the adjacent screen. Collected caches and cleared screen state persist while
the player travels around the current run.

## Reclaiming terrain

The hoe is both a defensive tool and the way the farm expands. With Hoe assigned
to `X`, swinging at clear, non-farmable ground leaves persistent worked-soil
marks. Enough swings
turn that tile into a permanent plot for the current run:

- homestead grass and meadow: 2 swings
- grove: 3 swings
- stonewild: 4 swings

Rocks, trees, caches, buildings, ponds, existing plots, and travel corridors
prevent tilling until the target ground is clear. Once a new plot is ready,
switch `X` to Farm and use it normally. Partial hoe progress, created plots,
and growing crops are stored on their screen and survive travel.

## Tool belt

On the overworld, `X` performs the selected tool action:

- **Hoe:** attacks blights and reclaims clear terrain.
- **Farm:** tills existing plots, plants seeds, and harvests ripe crops.

Tap `Z` to cycle `X` between Hoe and Farm. Hold `Z` for roughly half a second
to open the tool-belt sub-screen; use the D-pad to select explicitly, then
release `Z` to close it. The sub-screen pauses movement and world simulation.

## Controls

- D-pad: move and face.
- X: use the selected Hoe or Farm action.
- Tap Z: cycle X between Hoe and Farm.
- Hold Z: open the tool-belt sub-screen; arrows select, release closes.
- Seed selector: left/right ±1, up/down ±100, Z generates, X randomizes.
- Win screen: Z or X returns to the seed selector.

## Design pillars

- **Farm verbs are field verbs.** Tilling, planting, harvesting, and defending
  happen directly in the world.
- **Readable screen-by-screen travel.** The generated overworld uses nine
  128×128 screens, clear edge openings, and a central farm as its anchor.
- **Gentle pressure, quick recovery.** Blights cost time and crops, not a long
  run or an inventory full of progress.
- **Action-adventure clarity.** Facing, reach, tool feedback, and threats should
  be legible without a tutorial box.

## First-sketch question

Does the combination of directional farm interaction and light crop defense
feel like one coherent action-game loop?

## Deliberately out of scope

- smooth scrolling and camera-following maps
- town, NPCs, quests, dialogue, and shops
- full inventory screens, item wheels, or more than the two core tools
- seasons, weather, stamina, money, and crafting
- save data and long-form progression
- larger crop catalogs, enemy families, or bosses
- larger or infinite maps, procedural quests, loot tables, and permadeath

The first cart is a mechanical sketch. If its verbs feel good, a later pass can
grow outward into a Zelda-like overworld organized around fields, ruins, and
farmstead upgrades.
