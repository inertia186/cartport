# Pixel's Progress PICO-8 Workspace

This folder is the intended home for Pixel's Progress cart-source artifacts.

## Intended contents

Examples of what should live here as the project becomes real:
- `pixels-progress.p8` — primary editable source cart
- `pixels-progress.p8.png` — optional runtime/share artifact when useful, especially for native or native-like loading paths
- `pixels-progress-movement-v1.md` — the current sketch brief for the first cart pass
- `TODO.md` — immediate PICO-8-side checks after opening the cart
- tiny helper notes or scripts directly tied to the cart authoring loop

## Near-term goal

The current useful move is to keep iterating the real PICO-8 cart, then refresh the HTML export when the playable browser build should catch up.

Current first-cart artifacts:
- `sketch-contract.md` — minimum input contract for producing the first `.p8` sketch
- `pixels-progress-movement-v1.md` — concrete fill for the first movement-proof pass
- `pixels-progress.p8` — primary source cart to open and tune in actual PICO-8

## Sound sources

Pixel's Progress currently imports selected sounds from Gruber's **Pico-8 SFX Pack!** on the Lexaloffle BBS. Source: https://www.lexaloffle.com/bbs/?tid=34367

Current SFX map:
- `11` — shed pixels while jumping
- `16` — player falls out
- `42` — goal reached
- `46` — player hit
- `54` — sand lands
- `55` — jump

