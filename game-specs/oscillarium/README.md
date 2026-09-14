# Oscillarium

## Premise

Oscillarium is a PICO-8-minded waveform puzzle toy about learning how simple waves combine into a final signal.

The player is a visitor in a tiny signal museum — the **Oscillarium** — guided by a docent who insists on pronouncing it **Oscill-ARIUM**.

## Analysis Mode — Component Match

Primary question: can the player learn to recognize which two component waves produce a displayed target waveform?

Analysis Mode is the teaching/inspection mode. It builds the waveform literacy that a later Play Mode should spend on the real puzzle.

### Loop

1. Show a target waveform.
2. Show several candidate component waves.
3. Player selects exactly two candidates.
4. The game draws the summed waveform live.
5. If the sum matches the target, the exhibit advances.

### First candidate rules

- Use simple sine-like wave families first.
- Keep matching visual and readable before making it musical.
- Start with integer-ish frequencies and phase choices.
- Judge by intended pair identity in the first site prototype; later carts can score by numeric curve error.

### Audio stance

PICO-8 supports chip-audio cues through SFX channels, but the first design should not depend on arbitrary true waveform playback.

Current first pass:

- each component has a short signature cue
- Analysis Mode currently has eight component waveforms and eight hand-authored target combinations
- pressing `x` auditions the highlighted candidate
- pressing `z` selects/deselects the highlighted candidate
- when two components are selected, their cues layer on separate channels
- submit/correct/incorrect states have small feedback cues

The visual waveform remains the source of truth for Mode One; sound is an inspection aid and exhibit flavor.

## Play Mode Direction

Play Mode is not defined yet. Working intent: the real puzzle should require recognition skills learned in Analysis Mode, rather than simply repeating the same two-wave matching exercise.

Possible future puzzle shapes:

- tune machines/doors/creatures by recognizing the hidden component pair
- route energy through exhibits whose behavior reveals component waves
- repair unstable signals under time or move constraints
- use sound/shape recognition to pick tools before interacting with the environment

## Tone

Educational toy pretending to be a puzzle game.

Docent energy:

- “Welcome to the Oscill-ARIUM.”
- “Two waves enter. One confusing wiggle leaves.”
- “Please do not tap the glass. The sine waves are very sensitive.”

The joke should recur lightly, not dominate the puzzle.
