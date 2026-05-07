# Cartport

Cartport is a simple single-page app for browsing and playing curated pico-8 games in the browser.

## Inspiration

This project is loosely inspired by Anthony Martin's 2023 concept post, **"Idea: GameSeed Studio"**:
- https://hive.blog/llm/@inertia/idea-gameseed-studio.json

That original idea centered on a generative game-design platform with a few distinctive traits:
- game creation driven by rich natural-language prompts
- a strong culture of sharing design ideas and prompts
- local or self-contained execution rather than permissioned cloud dependence
- creativity shaped by hardware constraints

Cartport is a narrower, more practical version of that spirit.

## How Cartport Differs

Cartport is **not** trying to implement the full GameSeed Studio concept.

We are explicitly leaving out:
- seeds as the main unit of distribution
- distributed or custom hardware concerns
- FPGA/runtime architecture experiments
- local AI inference as a product requirement

Instead, Cartport focuses on two things:
- providing a lightweight shelf / launcher / publishing portal for small pico-8 games
- supporting a PICO-8-first development loop around those games

## Design Philosophy

The core idea is to treat **pico-8 itself as the constraint surface**.

Rather than inventing new hardware limitations, we lean into the existing fantasy-console limits and let those shape the games:
- tiny screen and strong visual economy
- limited input model
- compact code and data budgets
- a retro aesthetic that rewards clarity and cleverness
- mechanical simplicity over feature sprawl

Those limitations are not a bug. They are the aesthetic engine.

## Project Goal

Build a clean SPA where visitors can:
- browse a curated set of pico-8 games
- launch and play them directly in the site
- get a small amount of context for each game
- eventually explore a growing catalog of compact, well-designed experiments

## PICO-8-First Workflow

The recommended path is to use **actual PICO-8 as the primary design and iteration surface**.

Working model:
1. Describe the game or mechanic.
2. Turn that into a small PICO-8 sketch.
3. Iterate in actual PICO-8 first.
4. Export to HTML5 only when browser previewing or publishing is useful.

Repository shape:
- `pico8/<slug>/` — source-of-truth cart workspace
- `public/carts/<slug>/` — generated HTML5 export for Cartport
- `dist/` — built site output
- `Makefile` — canonical local run/export targets for PICO-8 carts

Treat these as source artifacts when they exist:
- `.p8`
- `.p8.png`
- cart-local helper notes/scripts directly supporting authoring

Treat these as generated artifacts:
- HTML5 export output under `public/carts/<slug>/`
- anything in `dist/`

## Embedding PICO-8 Games

When Cartport needs a web-playable version, the preferred publishing path is still **PICO-8's native HTML export**.

Why this approach:
- it uses the official PICO-8 web runtime rather than a homebrew emulator layer
- it keeps each game self-contained
- it preserves PICO-8 as the runtime truth while giving Cartport a clean web surface

Practical model:
1. Export a cart from PICO-8 as HTML5.
2. Put the exported files under `public/carts/<slug>/`.
3. Point a game entry at `carts/<slug>/index.html` so Vite can resolve it under the deployed base path.
4. Load that export in the site inside the single active player frame.

Recommended local seam:
- use `make run CART=<slug>` to open a source cart in PICO-8
- use `make export-html CART=<slug>` to refresh Cartport's generated HTML export
- treat the Makefile as the canonical bridge between cart authoring and Cartport publishing

The export target also cache-busts the generated PICO-8 cart script reference inside `public/carts/<slug>/index.html`, so GitHub Pages does not keep serving stale cart JavaScript after an export changes.

Current practical export note:
- PICO-8 HTML export can refuse to build a cart that does not yet have a captured label image; if export says `please capture a label first`, save a label in PICO-8 and rerun the Make target

Example local path:
- `public/carts/your-cart-here/index.html`

### Cartridge downloads

Cart entries can expose their source/share cartridge with a `.p8.png` download link for handheld/kiosk-style browsing. The portal uses a normal same-origin anchor with the HTML `download` attribute, which is the lightweight SPA-native way to ask the browser to save the cartridge instead of navigating to it.

`public/_headers` also declares `Content-Disposition: attachment` for `.p8.png` files on static hosts that honor `_headers` files, such as Cloudflare Pages or Netlify. GitHub Pages does not support custom response headers from repository files, so on GitHub Pages the behavior is best-effort browser instruction rather than a guaranteed response-header policy.

Source note:
- The PICO-8 FAQ states that cartridges can be exported to HTML5.
- https://www.lexaloffle.com/pico-8.php?page=faq

## Current Game Concept

### Pixel's Progress

The first game concept currently in the portal is **Pixel's Progress**.

Core constraint:
- the player character is a single pixel

Level 1 direction:
- layout is reminiscent of early Kid Icarus screen composition
- the entire level is visible on one screen
- no scrolling
- start position is the bottom left
- the player climbs to the top of the screen
- then moves right and descends through the middle of the screen
- then moves right again and climbs to the top-right goal
- the resulting path is roughly **N-shaped**

Design implication:
- because the avatar is only one pixel, the stage has to do extra work to communicate safe footing, hazards, pathing, and progress

## Current Stack

- Vite
- React

## Development

```bash
npm install
npm run dev
npm run build
```

## GitHub Pages

This repo includes a GitHub Actions workflow at `.github/workflows/pages.yml`.

For the `inertia186/cartport` project site, the Pages build uses:

```bash
npm run build:pages
```

That runs Vite with `--base=/cartport/`, so built assets and embedded cart exports resolve correctly at:

```text
https://inertia186.github.io/cartport/
```

After pushing to GitHub, enable Pages in repository settings with **Source: GitHub Actions**.
