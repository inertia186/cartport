Use the $imagegen skill.

Generate a PICO-8 cartridge label image for **Oubliette**, a turn-by-turn first-person dungeon crawler.

Purpose:
- This will replace the current hand-authored placeholder cartridge label at `public/carts/oubliette.p8.png`.
- It should read well at PICO-8 label scale and as a Cartport shelf thumbnail.

Composition:
- 128x128 square pixel-art title/label image.
- A dark stone dungeon corridor receding into the center.
- Torch glow, an iron gate or stairs descending, and one small monster silhouette or skull shape.
- Title text: `OUBLIETTE` near the top if it can be crisp; if text becomes messy, prioritize readable dungeon mood over text.

Style constraints:
- Strict PICO-8-inspired 16-color pixel art.
- Crisp nearest-neighbor look, no antialias blur, no gradients that do not survive palette reduction.
- No watermark, no signature, no modern UI chrome.
- High contrast and readable at 128x128.

Save/copy the final selected image into this project at:

`public/carts/oubliette.p8.png`

If generated high-resolution, create a 128x128 nearest-neighbor downsampled version with at most 16 actually used colors at that same path.

Do not modify source code. Report saved path and friction.
