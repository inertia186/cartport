# PICO-8 Source Workspace

This directory is the source-of-truth side of Cartport for PICO-8-first development.

## Intended shape

- `pico8/<slug>/` — per-game working area for editable cart sources and cart-local notes
- `pico8/common/` — shared helper material if needed later
- `public/carts/<slug>/` — generated/published HTML5 exports for Cartport previewing and web play

## Source vs generated

Treat these as **source artifacts** when they exist:
- `.p8` — the default primary editable source artifact
- `.p8.png` — optional runtime/share artifact, useful when loading on native or native-like PICO-8 hardware/runtime paths
- cart-local helper files that directly support authoring

Treat these as **generated/publishing artifacts**:
- HTML5 export output under `public/carts/<slug>/`
- anything in `dist/`

## Working loop

1. Describe the game or mechanic.
2. Turn that into a small PICO-8 sketch.
3. Iterate in actual PICO-8 first.
4. Export to HTML5 only when a browser preview or publishing surface is useful.

The repo-level `Makefile` is the canonical seam for that loop:
- `make run CART=<slug>` opens `pico8/<slug>/<slug>.p8`
- `make export-html CART=<slug>` refreshes `public/carts/<slug>/`

Cartport is the shelf and optional web surface. The cart is the thing.

When a game needs a first cart, prefer giving it a small sketch contract first rather than jumping straight from vague design talk into implementation. See `pico8/pixels-progress/sketch-contract.md` for the current example shape.
