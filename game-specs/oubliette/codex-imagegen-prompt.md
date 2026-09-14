# Codex.app `$imagegen` prompt for Oubliette

Use the `$imagegen` skill.

Generate a PICO-8 style interface concept image for **Oubliette**, adapted to a 128x128 PICO-8 game screen.

Use the SwiftyDungeon reference images in this repo as composition and mood references:
- `/Users/anthony/src/SwiftyDungeon/output/imagegen/interface-concept.png`
- `/Users/anthony/src/SwiftyDungeon/docs/screenshots/swifty-dungeon-app.png`

Required layout:
- Center / upper-left: playable first-person dungeon viewport, torch-lit stone corridor, strong depth perspective.
- Bottom area: small character readout plus on-screen arrow-key / D-pad controls and `Z` / `X` action hints.
- Right sidebar: player status and telemetry: HP, XP, level, floor, gold, potions, keys, equipment, compact inventory icons.
- Overall: readable as a real PICO-8 game screenshot, not just mood art.

Style constraints:
- Strict PICO-8-inspired pixel art.
- 16-color feel; high contrast; crisp edges.
- No watermark.
- Avoid illegible dense text; use icons and short labels.
- Make the layout useful as implementation guidance for `pico8/oubliette/oubliette.p8`.

Save/copy the final selected image into the Cartport project at:

`public/carts/oubliette-interface-concept.png`

If the generated image is high-resolution, also create a 128x128 nearest-neighbor downsampled version with at most 16 used colors at the same path.

Do not modify source code unless explicitly asked.
Report the saved path and any friction.
