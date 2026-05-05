# Pixel's Progress Movement v1 (archived baseline)

## Sketch name
`pixels-progress-movement-v1`

This was the initial movement-proof brief. It is kept as historical context; the current cart has since grown into a two-level mechanic prototype with lava, sand, growth, rotation, loop pressure, and a Cartport export.

## Primary question
Does a one-pixel character feel readable, fair, and controllable in a full-screen proving room?

## Premise
A single-pixel character tries to cross a chamber while preserving precision.

## Verbs
- move left / right
- jump
- fall / gravity
- restart

## Room shape
- full-screen proving room
- route is a rough N-shape
- initially one room only
- no scrolling

## Start
- bottom-left

## Goal
- top-right

## Failure / reset
- falling or getting stuck leads to immediate restart
- restart should be frictionless

## Out of scope
- enemies
- combat
- wall jump
- dash
- crouch
- ledge grab
- multi-room progression at this initial baseline
- full growth system at this initial baseline

## First implementation bias
The first cart should prove movement readability, not content breadth.

That means:
- use placeholder visuals
- keep collision simple and legible
- make restart obvious and fast
- prefer one clean jump arc over feature expansion
