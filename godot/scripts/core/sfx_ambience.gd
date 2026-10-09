class_name SfxAmbience
extends RefCounted
## Drives the Sfx ambience beds from the game state: wind on the surface, a low drone in the
## cave, and creeper bubbling that swells with how much creeper is around the listener.

const EVERY := 0.25    # seconds between creeper samples
const RADIUS := 12     # cells sampled around the listener
const STEP := 2
const FULL := 60.0     # summed depth that counts as fully surrounded

var _wait := 0.0
var _goo := 0.0


func update(g: Node, dt: float) -> void:
	var cave: bool = g.mode == "cave"
	var w: World = g.cave if cave else g.surface
	_wait -= dt
	if _wait <= 0.0:
		_wait = EVERY
		_goo = _sample(w)
	var quiet := 0.5 if g.paused or g.over else 1.0
	Sfx.set_bed("wind", (0.0 if cave else 0.35) * quiet)
	Sfx.set_bed("cave", (0.6 if cave else 0.0) * quiet)
	Sfx.set_bed("creeper", 0.8 * _goo * quiet)


func _sample(w: World) -> float:
	if w == null or w.creeper == null:
		return 0.0
	var c := w.grid.world_to_cell(Sfx.listener.x, Sfx.listener.z)
	var sum := 0.0
	for dz in range(-RADIUS, RADIUS + 1, STEP):
		for dx in range(-RADIUS, RADIUS + 1, STEP):
			var x := c.x + dx
			var z := c.y + dz
			if x < 0 or z < 0 or x >= w.grid.w or z >= w.grid.h:
				continue
			var near := 1.0 - Vector2(dx, dz).length() / (RADIUS * 1.5)
			sum += maxf(0.0, w.creeper.depth_at(x, z)) * maxf(0.0, near)
	return clampf(sum / FULL, 0.0, 1.0)
