# Pixel's Progress

## Premise

Pixel's Progress is a PICO-8 platformer built around an extreme visual and mechanical constraint: the player character begins as a single pixel.

The game should feel:
- simple
- precise
- fair
- readable

The design goal is not complexity for its own sake. The smallness of the player character should drive the entire experience.

## Core Design Pillars

- **Readable at a glance**
- **Precise but fair**
- **Tiny but expressive**
- **One more try energy**
- **Simplicity is part of the fiction**

## High-Level Concept

The player starts as one pixel and tries to remain small enough to make progress through the level.

This is not a combat-first platformer. It is primarily about:
- movement feel
- spatial readability
- route comprehension
- protecting smallness

## Movement Spec v0

### Core moves
- left / right movement
- single jump
- gravity / falling
- light air control

### Explicitly not included
- no double jump
- no wall jump
- no dash
- no attack
- no crouch
- no ledge grab

### Feel goals
- the player should feel small
- the player should feel fragile
- the player should feel controllable
- movement should never feel slippery or random

### Recommended behavior

#### Horizontal movement
- quick acceleration
- quick stop
- slightly slower turning in air than on ground

#### Jump
- one clean arc
- enough height to clearly read intended ledges
- no weird trick jumps required in Level 1

#### Falling
- a little faster than rising
- enough weight to make drops feel intentional

### Hidden fairness features
- coyote time
- jump buffering

These improve feel without making the move set more visibly complex.

## Growth Mechanic v0

Hazards do not deal traditional damage.

Instead:
- hazard contact adds a pixel to the player
- the resulting body shape rotates by 90° / 180° / 270°
- the player gradually becomes too awkward to navigate cleanly
- too many added pixels or an unlucky shape can make a run non-viable

This mechanic reframes damage as burden, corruption, or loss of simplicity.

### Design intent
- the player is not mainly defending health
- the player is defending **smallness**
- the level itself becomes the proof of whether the current body can still progress

### Likely consequences of added pixels
Added pixels may eventually cause:
- reduced ability to fit through tight spaces
- worse jump performance or heavier feel
- less precision on narrow landings
- more accidental contact with hazards or geometry
- routes meant for a 1-pixel body to become impractical or impossible


### Current hazard types

- **Lava** falls, settles into terrain surfaces, remains dangerous, and causes pixel growth plus shape rotation on contact.
- **Sand** falls from random top-screen positions. Falling sand is dangerous, but resting sand becomes harmless stackable terrain. Sand stacks as blocky one-pixel columns; it intentionally does not roll or form granular hills.

The final level loops back to the first level, and each completed loop makes sand spawn slightly more frequently.

### Important principle
Do not make added pixels feel like generic slowdown only.

The strongest version of the mechanic is spatial: the body changes orientation and shape, and therefore the level changes.

## Restart / Failure Loop

A run does not need to end only because the player "dies."

Instead, the player may realize:
- they have accumulated too many pixels
- the current route no longer works
- the run is no longer viable

At that point, the player should be able to restart quickly and deliberately.

### Restart principles
- restart should be fast
- restart should be frictionless
- it should be obvious when size is the reason progress stalled

The player should think:
- "I got too big"

Not:
- "the game randomly became impossible"

## Level 1 Concept

Level 1 should be a full-screen, no-scroll room.

Inspirations and qualities:
- reminiscent of early Kid Icarus-style screen composition
- the entire level is visible at once
- the room should read more like a composed chamber than a scrolling corridor

### Route structure
The intended path is roughly **N-shaped**:
- start in the bottom-left
- climb upward through the left third
- transition into the middle third at the top
- descend through the middle third
- transition into the right third at the bottom
- climb upward through the right third
- reach the goal in the top-right

### Structural rule
Each third of the room is a distinct area:
- **left third:** ascent chamber
- **middle third:** descent chamber
- **right third:** ascent chamber

Transitions are gated by height:
- the player can only enter the middle third from the top
- the player can only enter the right third from the bottom

### Level 1 teaching goals
- left third teaches movement and trust
- middle third teaches controlled descent and route reading
- right third asks for a final proof of mastery

## Left-Third Module Note

An earlier vertical sketch that looked too staircase-heavy for the whole room may still be useful as a movement-testing column or as the seed for the left-third ascent module.

That vertical module is useful for testing:
- short hop
- full jump
- edge jump
- drop to narrow landing
- spike-adjacent landing
- precision jump

## Design Guidance So Far

### What should create challenge
- spacing
- commitment
- landing precision
- route reading
- preserving smallness

### What should not create challenge, at least early
- oversized move lists
- hidden advanced techniques
- visual ambiguity
- punishment with unclear cause

### Rule of thumb
A room should never require the player to wonder whether they are missing some hidden advanced move.

The answer should remain legible:
- move
- jump
- try again smarter

## Level Family Direction

The current proving room is now the canonical **Level 1 N-family** room:
- three separated vertical chambers
- transfer from left to middle at the top
- transfer from middle to right at the bottom
- hazard/growth pressure aimed at preserving smallness through a known structure
- current cart flow intent: reaching the Level 1 goal should be able to advance into the Level 2 Z-family room

The likely next room is a **Level 2 Z-family** experiment:
- route emphasis shifts from chamber ascent/descent to high traverse, directional break, and lower traverse
- growth pressure should test commitment and route reversal rather than only climb precision

See also:
- `game-specs/pixels-progress/layout-doctrine.md`

## Open Questions

- How exactly should added pixels be represented visually over longer play, beyond the current first-pass accretion behavior?
- At what thresholds does added size begin to affect movement or collision in the best way?
- How much jump-shedding should be allowed as in-level recovery versus reset-only recovery?
- How many hazard contacts should Level 1 tolerate before the intended route breaks down?
- What is the cleanest first Z-family room for Level 2?
