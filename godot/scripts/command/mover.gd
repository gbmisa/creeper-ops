class_name Mover
## Relocating structures, CW3 style: lift off, fly over terrain and creeper, settle, reconnect.
## Weapons keep their ammo but don't fire or receive packets while airborne, except a `roams`
## weapon (Thor), which fires from its magazine in flight. The Command Node produces nothing
## while flying. Thor is a "flying" def: it always hovers.

const HOVER := 4.0  # metres Thor floats above ground/creeper


static func start(mgr, s: Structure, x: int, z: int) -> void:
	var g: Grid = mgr.world.grid
	mgr.vacate(s)
	var to := g.cell_ground(x, z)
	var from := s.pos
	var cruise := maxf(from.y, to.y)
	for i in 9:  # clear whatever terrain lies between
		var p := from.lerp(to, i / 8.0)
		cruise = maxf(cruise, g.smooth_y(p.x, p.z))
	cruise += Config.LIFT_HEIGHT
	var travel := Vector2(to.x - from.x, to.z - from.z).length() / (float(s.def.move_speed) * Upgrades.mult("move"))
	s.flight = { "from": from, "to": to, "cruise": cruise, "t": 0.0, "travel": travel }
	s.x = x
	s.z = z
	mgr.occupy(s)
	mgr.dirty = true
	Sfx.play("lift", s.pos)


## Advance a flight. Returns true when it has just landed.
static func update(s: Structure, dt: float) -> bool:
	var f: Dictionary = s.flight
	f.t += dt
	var lift := Config.LIFT_TIME
	var t: float = f.t
	var k := clampf((t - lift) / maxf(0.01, f.travel), 0.0, 1.0)
	k = k * k * (3.0 - 2.0 * k)
	var p: Vector3 = f.from.lerp(f.to, k)
	var y: float
	if t < lift:
		y = lerpf(f.from.y, f.cruise, _ease(t / lift))
	elif t < lift + f.travel:
		y = f.cruise
	else:
		y = lerpf(f.cruise, f.to.y, _ease((t - lift - f.travel) / lift))
	p.y = y
	s.pos = p
	s.node.position = p + Vector3(0, hover_offset(s), 0)
	if t >= lift * 2.0 + f.travel:
		s.pos = f.to
		s.node.position = f.to + Vector3(0, hover_offset(s), 0)
		s.flight = null
		return true
	return false


static func hover_offset(s: Structure) -> float:
	return HOVER if s.def.get("flying", false) else 0.0


static func _ease(k: float) -> float:
	k = clampf(k, 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)
