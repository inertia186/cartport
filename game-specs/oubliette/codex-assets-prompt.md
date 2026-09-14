Use the $imagegen skill.

Generate a PICO-8 pixel-art asset reference sheet for **Oubliette**, a turn-by-turn first-person dungeon crawler.

Purpose:
- Replace the current primitive stand-in visual direction with mined generated reference art.
- This image is a reference sheet for implementing PICO-8 primitive/tile-like visuals; it does not need to be directly used by the cart runtime yet.

Required contents:
- Wall texture swatches: rough stone, mossy stone, cracked brick, torch-lit stone.
- Floor/ceiling themes: dungeon floor, damp cellar, dark oubliette pit, stairwell.
- First-person dungeon elements: door, locked gate, stairs down, chest, torch, wall niche.
- Monsters: rat, slime, bat, skeleton, goblin.
- Items/icons: potion, key, gold coin, sword, shield, stairs marker, heart/HP, XP pip.
- UI pieces: tiny HP bar, XP bar, inventory slots, compass/heading marker.

Style constraints:
- Strict PICO-8-inspired 16-color pixel art.
- Tile/sprite sheet layout, crisp edges, no watermark.
- No long text labels; small icon groupings are enough.
- Should remain useful after 128x128 downsampling and palette reduction.

Save/copy the final selected image into this project at:

`public/carts/oubliette-asset-reference.png`

If generated high-resolution, create a 128x128 nearest-neighbor downsampled version with at most 16 actually used colors at that same path.

Do not modify source code. Report saved path and friction.
