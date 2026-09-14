# Oscillarium Sketch Contract

## Sketch name

`oscillarium-analysis-mode-v0`

## Primary question

Can a player learn waveform recognition by looking at a target waveform and choosing the two component waveforms that would produce it?

## Premise

The player is visiting the Oscillarium, a tiny signal museum where Analysis Mode teaches waveform recognition by reconstructing combined waves. A later Play Mode should use that recognition skill in a more game-like puzzle.

## Verbs

- inspect target waveform
- use a generalized focus shell to choose target area or component area
- focus into the target area and select different combined target waveforms
- focus into the component area and move among candidate waves with up/down/left/right
- audition highlighted candidate as a short chip-audio cue
- select / deselect two candidate waves
- immediately evaluate when the second component is selected
- hear correct selected pairs layered on separate channels
- advance after a correct match

## Room / screen shape

Single-screen exhibit layout:

- target waveform at the top
- candidate component cards below
- no reserved selected/sum/status area; feedback appears transiently as an overlay/toast
- compact navigation hints at the bottom edge

Navigation model:

- initial focus is the component area
- `x` backs out to area selection
- area selection chooses between target/top and components/bottom
- `z` focuses into the selected area
- focused target area uses arrows to change combined target waveform
- focused component area uses arrows to move among component waves; `z` picks
- there is no live summed-wave preview or reserved feedback band in Analysis Mode; the second pick is evaluated blindly as pass/fail, and correct/incorrect feedback is transient

## Success

The selected two waveforms are the intended components of the target waveform.

## Failure / reset

Incorrect two-wave selections immediately clear the selected pair, reset the combined waveform display, flash a red wrong-pair indicator, and keep the same puzzle active.

Correct two-wave selections immediately flash a green correct-pair indicator and unlock the next exhibit.

## Play Mode placeholder

Play Mode is intentionally undefined for now. The key design rule is that it should reward recognition learned in Analysis Mode instead of merely adding more menu matching.

## Out of scope for first cart

- arbitrary audio waveform playback
- exact DSP-accurate rendering of summed waveforms as audio
- freeform waveform editing
- more than two selected components
- complex scoring by curve distance
- procedural puzzle generation beyond a small hand-authored set

## First implementation bias

Prioritize readability of waveform composition over sound fidelity. PICO-8 SFX can add exhibit flavor later, but the first mode should work visually even with audio muted.
