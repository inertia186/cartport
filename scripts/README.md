# Scripts

Reserved for small helper scripts that support the PICO-8-first workflow.

Current stance:
- prefer the repo `Makefile` as the first command surface for routine cart run/export actions
- add scripts only when the Make targets would otherwise become noisy or repetitive

Examples:
- copying or organizing exported HTML5 builds into `public/carts/<slug>/`
- light packaging helpers
- asset shims that do not replace the actual PICO-8 authoring loop

Avoid turning this into the primary game-runtime layer. PICO-8 remains the main iteration surface.
