# Pixel's Progress Sketch Contract (historical)

This file defines the smallest useful input needed to turn a game idea into a first `.p8` sketch. Pixel's Progress has moved beyond this first-sketch stage; keep this as a template/history document, not as the current scope of the cart.

The goal is not to fully design the game up front. The goal is to provide enough structure to make a real cart worth opening in PICO-8.

## Minimum required inputs

A first `.p8` sketch should not begin until these are known:

### 1. Core premise
One or two sentences answering:
- what the player is
- what the player is trying to do
- what makes this game specifically interesting

For Pixel's Progress:
- The player is a single pixel.
- The player is trying to cross a room while staying small enough to make progress.

### 2. Verbs
List only the moves the sketch must support now.

For the first sketch, keep this tiny:
- move left / right
- jump
- fall / gravity
- restart

Anything not on this list is out of scope for sketch v1.

### 3. One proving room
Define a single room or chamber that proves the current question.

For sketch v1, answer:
- is the room full-screen or scrolling?
- where does the player start?
- where is the goal?
- what route shape should the room teach?

For Pixel's Progress v1:
- full-screen
- start bottom-left
- goal top-right
- route is a rough N-shape

### 4. Primary question
Pick exactly one design question the sketch exists to answer.

Examples:
- Does one-pixel movement feel readable and fair?
- Does the first room layout teach the route clearly?
- Does early growth immediately add tension or just confusion?

A sketch with multiple primary questions tends to get muddy.

### 5. Failure / reset rule
State what counts as failure in the sketch and how the player recovers.

For early Pixel's Progress sketches this can be as simple as:
- falling or getting stuck means quick restart
- restart should be immediate and frictionless

## Optional but useful inputs

These help, but are not required for the first sketch:
- temporary palette or visual motif
- placeholder hazard idea
- whether growth is present yet
- specific jump-feel targets
- one or two teaching beats for the room

## Sketch tiers

### Sketch v1 — movement proof
Use when the main question is movement readability.

Required:
- premise
- verbs
- one proving room
- one primary question
- failure/reset rule

Do **not** require:
- enemies
- growth mechanic
- polished art
- multi-room progression

### Sketch v2 — mechanic proof
Use after movement basically works.

Adds one mechanic question, such as:
- first growth threshold
- one enemy contact behavior
- one spatial consequence of becoming larger

Still avoid broad content expansion.

## Default bias for Pixel's Progress

Start with **Sketch v1 — movement proof**.

That means the next real cart should probably contain:
- one room
- one-pixel player
- left/right/jump/gravity/restart
- fast reset
- no required combat
- no extra move list
- growth only if it serves the single chosen question

## Hand-off template

When turning a description into a `.p8` sketch, fill this in:

```text
Sketch name:
Primary question:
Premise:
Verbs:
Room shape:
Start:
Goal:
Failure/reset:
Out of scope:
```

## First suggested fill for Pixel's Progress

```text
Sketch name: pixels-progress-movement-v1
Primary question: Does a one-pixel character feel readable, fair, and controllable in a full-screen proving room?
Premise: A single-pixel character tries to cross a chamber while preserving precision.
Verbs: move left/right, jump, fall, restart
Room shape: full-screen N-route chamber
Start: bottom-left
Goal: top-right
Failure/reset: falling or getting stuck leads to immediate restart
Out of scope: enemies, combat, wall jump, dash, multi-room progression, full growth system
```
