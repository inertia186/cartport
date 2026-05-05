# Pixel's Progress TODO

## Immediate next checks in actual PICO-8

- Open `pixels-progress.p8`
- Verify the cart loads cleanly
- Test whether one-pixel visibility is acceptable against the current background
- Test whether the jump arc feels readable and fair
- Test whether jump-shedding extra pixels feels like useful relief instead of muddying the growth pressure
- Test whether the walled three-chamber room reads naturally: left climb shaft, middle drop shaft, then right-side destination shaft
- Verify fall-out X restart remains fast and intentional without a confirmation prompt
- Capture a cart label in PICO-8 so `make export-html CART=pixels-progress` can produce the first Cartport-facing HTML build

## Likely first edits after opening

- tune target-speed acceleration response, especially lower-to-higher platform jumps
- tune jump velocity and gravity
- continue tuning platform spacing and wall openings, especially the top-left transfer into middle and the bottom-middle transfer into right
- decide later whether the HUD should stay persistent, become contextual, or collapse into a dismissible prompt once the room stops changing so quickly
- decide whether the player needs a tiny visibility aid beyond a single bright pixel
- decide whether sketch v1 should include coyote time immediately or wait for the second pass

## Next validation after traversal

- Verify that touching the goal produces a clear, satisfying success state
- Verify post-goal continue/retry flow still reads clearly now that final level loops back to Level 1
- Verify that falling lava settles into readable floor-line hazards, that lava contact adds/rotates the current shape in a readable way, and that chaotic FX reads as "bad contact" rather than reward juice
- Verify that leaving the play field below the floor now behaves intentionally as an out-of-bounds reset state rather than as accidental collision leakage
- Test the `room_id` loop seam across N → Z → N while sand spawn frequency increases
- Keep future room-family doctrine in `game-specs/pixels-progress/layout-doctrine.md`
- Check whether the simpler collision hull still feels honest once the visual body becomes asymmetrical
- Check whether size 2-4 changes route viability in an interesting spatial way instead of only feeling like generic slowdown

## Still out of scope

- moving enemies
- combat or HP-style damage
- combat
- art polish
- full granular sand physics / rolling hills
