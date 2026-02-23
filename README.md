# PixelPlanets

A collection of Godot shaders to generate pixel planets. Try a web version here: https://deep-fold.itch.io/pixel-planet-generator

The web version only exposes some options, to use all options (noise generation, lighting, colors, etc.) you have to use the actual shaders.

Ports to other engines:
 * Monogame port by EnthusiastGuy: https://github.com/EnthusiastGuy/MonoGame-Pixel-Planets
 * Unity port by Hmc: https://github.com/hmcGit/UniPixelPlanet
 * Unity port by Marcus-garvey (based on port by Hmc): https://github.com/marcus-garvey/UniPixelPlanet
 * Defold port by Selimanac: https://github.com/selimanac/defold-pixel-planets

## Headless spritesheet generation

Yes — you can generate spritesheets programmatically with fixed parameters.
A ready-to-run script is included at `scripts/generate_spritesheet.gd`.

Example:

```bash
godot4 --headless --path . --script res://scripts/generate_spritesheet.gd -- \
  --type=terran_wet --seed=12345 --pixels=128 --frames-x=12 --frames-y=6 --pixel-margin=1 --output=planet_sheet.png
```

Supported `--type` values:
`terran_wet`, `terran_dry`, `islands`, `no_atmosphere`, `gas_giant_1`, `gas_giant_2`,
`ice_world`, `lava_world`, `asteroid`, `black_hole`, `galaxy`, `star`.

Run with `--help` to print all parameters and defaults.
