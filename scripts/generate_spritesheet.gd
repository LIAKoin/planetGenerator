extends SceneTree

const PLANETS := {
	"terran_wet": "res://Planets/Rivers/Rivers.tscn",
	"terran_dry": "res://Planets/DryTerran/DryTerran.tscn",
	"islands": "res://Planets/LandMasses/LandMasses.tscn",
	"no_atmosphere": "res://Planets/NoAtmosphere/NoAtmosphere.tscn",
	"gas_giant_1": "res://Planets/GasPlanet/GasPlanet.tscn",
	"gas_giant_2": "res://Planets/GasPlanetLayers/GasPlanetLayers.tscn",
	"ice_world": "res://Planets/IceWorld/IceWorld.tscn",
	"lava_world": "res://Planets/LavaWorld/LavaWorld.tscn",
	"asteroid": "res://Planets/Asteroids/Asteroid.tscn",
	"black_hole": "res://Planets/BlackHole/BlackHole.tscn",
	"galaxy": "res://Planets/Galaxy/Galaxy.tscn",
	"star": "res://Planets/Star/Star.tscn",
}

func _initialize() -> void:
	var options = _parse_args(OS.get_cmdline_user_args())
	if options.help:
		_print_help()
		quit(0)
		return

	if not PLANETS.has(options.type):
		push_error("Unknown --type '%s'. Use --help to see valid values." % options.type)
		quit(2)
		return

	if options.frames_x <= 0 or options.frames_y <= 0:
		push_error("--frames-x and --frames-y must be > 0")
		quit(2)
		return

	var planet_scene := load(PLANETS[options.type]) as PackedScene
	if planet_scene == null:
		push_error("Failed to load planet scene for type '%s'" % options.type)
		quit(1)
		return

	var viewport := SubViewport.new()
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = true
	root.add_child(viewport)

	var holder := Control.new()
	viewport.add_child(holder)

	var planet := planet_scene.instantiate()
	holder.add_child(planet)

	seed(options.seed)
	planet.set_seed(options.seed)
	planet.set_pixels(options.pixels)
	planet.set_dither(options.dither)
	planet.position = options.pixels * 0.5 * (planet.relative_scale - 1.0) * Vector2.ONE
	viewport.size = Vector2(options.pixels, options.pixels) * planet.relative_scale

	await process_frame

	var frame_w: int = int(options.pixels * planet.relative_scale)
	var frame_h: int = int(options.pixels * planet.relative_scale)
	var image_w: int = options.frames_x * frame_w + options.frames_x * options.pixel_margin + options.pixel_margin
	var image_h: int = options.frames_y * frame_h + options.frames_y * options.pixel_margin + options.pixel_margin
	var spritesheet := Image.create(image_w, image_h, false, Image.FORMAT_RGBA8)

	planet.override_time = true
	var index := 0
	for y in range(options.frames_y):
		for x in range(options.frames_x + 1):
			planet.set_custom_time(lerp(0.0, 1.0, float(index) / float((options.frames_x + 1) * options.frames_y)))
			await process_frame
			if index != 0:
				var frame := viewport.get_texture().get_image()
				var source := Rect2i(0, 0, frame_w, frame_h)
				var destination := Vector2i((x - 1) * frame_w + x * options.pixel_margin, y * frame_h + (y + 1) * options.pixel_margin)
				spritesheet.blit_rect(frame, source, destination)
			index += 1

	planet.override_time = false
	var result := spritesheet.save_png(options.output)
	if result != OK:
		push_error("Failed to save PNG to '%s' (error code %s)" % [options.output, result])
		quit(1)
		return

	print("Saved spritesheet: %s" % options.output)
	quit(0)

func _parse_args(raw_args: PackedStringArray) -> Dictionary:
	var parsed := {
		"type": "terran_wet",
		"seed": 1,
		"pixels": 100,
		"frames_x": 8,
		"frames_y": 8,
		"pixel_margin": 0,
		"dither": true,
		"output": "spritesheet.png",
		"help": false,
	}

	for arg in raw_args:
		if arg == "--help" or arg == "-h":
			parsed.help = true
			continue
		if not arg.contains("="):
			continue

		var parts := arg.split("=", false, 1)
		if parts.size() != 2:
			continue

		var key := parts[0].trim_prefix("--")
		var value := parts[1]
		match key:
			"type":
				parsed.type = value
			"seed":
				parsed.seed = int(value)
			"pixels":
				parsed.pixels = int(value)
			"frames-x":
				parsed.frames_x = int(value)
			"frames-y":
				parsed.frames_y = int(value)
			"pixel-margin":
				parsed.pixel_margin = int(value)
			"dither":
				parsed.dither = value.to_lower() in ["1", "true", "yes", "on"]
			"output":
				parsed.output = value

	return parsed

func _print_help() -> void:
	print("""
Headless spritesheet generator for PixelPlanets.

Usage:
  godot4 --headless --path . --script res://scripts/generate_spritesheet.gd -- \\
    --type=terran_wet --seed=123 --pixels=128 --frames-x=12 --frames-y=6 --pixel-margin=1 --output=planet_sheet.png

Parameters:
  --type           Planet preset key. Available: %s
  --seed           Integer seed (default: 1)
  --pixels         Base resolution in pixels for one frame (default: 100)
  --frames-x       Number of columns (default: 8)
  --frames-y       Number of rows (default: 8)
  --pixel-margin   Empty border between frames in pixels (default: 0)
  --dither         true/false (default: true)
  --output         Output PNG path (default: spritesheet.png)
""" % ", ".join(PLANETS.keys()))
