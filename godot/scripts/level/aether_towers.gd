class_name AetherTowers
extends RefCounted
## Aether Towers: the Forge's income. Every tower starts in creeper hands. The Operative walks
## up, presses [E] and holds the ground for AETHER_CAPTURE_TIME (stay close, keep it dry).
## A held tower trickles Aether. Creeper deeper than AETHER_RETAKE_DEPTH sitting on it for
## AETHER_RETAKE_TIME takes it back, and the Operative must return. Levels list cells under
## "aether_towers" (surface and cave). This is the FPS half feeding the command half.

const ENEMY := Color("7a3a8a")
const OURS := Color("e0b0ff")

var world: World
var towers: Array[Dictionary] = []
var op_pos := func() -> Variant: return null  # injected: Operative feet in THIS world, or null


func _init(w: World, cells: Array) -> void:
	world = w
	for c in cells:
		_make(c)
	w.updaters.append(update)


func held() -> int:
	return towers.filter(func(t): return t.ours).size()


func _make(c: Vector2i) -> void:
	var node := Node3D.new()
	var base := StructureMeshes.mat(Color("2a2036"), 0.4, 0.5)
	StructureMeshes.cyl(node, 0.5, 1.1, 1.0, base, 0.0, 6)
	StructureMeshes.cyl(node, 0.25, 0.45, 2.2, base, 1.0, 6)
	var crystal := StructureMeshes.box(node, Vector3(0.7, 1.4, 0.7), StructureMeshes.mat(ENEMY, 0.1, 0.2, ENEMY, 1.2), Vector3(0, 4.2, 0))
	crystal.rotation = Vector3(0.6, 0, 0.6)
	var pos := world.place_at(node, c.x, c.y)
	var bar := Bar.new(2.0, 5.6)
	bar.visible = false
	node.add_child(bar)
	world.grid.blocked[world.grid.idx(c.x, c.y)] = 1
	var t := { "x": c.x, "z": c.y, "node": node, "pos": pos, "crystal": crystal, "bar": bar,
		"ours": false, "capturing": false, "progress": 0.0, "lost": 0.0, "acc": 0.0 }
	towers.append(t)
	world.interactables.append({ "pos": pos, "radius": Config.AETHER_CAPTURE_RANGE,
		"prompt": func(): return _prompt(t),
		"use": func():
			if not t.ours and not t.capturing and not _wet(t):
				t.capturing = true
				Sfx.play("click")
				Bus.say("Uplink started. Hold the tower for %ds." % Config.AETHER_CAPTURE_TIME, "info") })
	world.markers.append({ "pos": pos + Vector3(0, 6.2, 0), "color": Color("d38cff"), "minor": true,
		"label": func(): return "Aether Tower (yours)" if t.ours else "Aether Tower: capture [%s]" % Keybinds.short("use"),
		"visible": func(): return true })


func _wet(t: Dictionary) -> bool:
	return world.creeper.depth_at(t.x, t.z) > Config.AETHER_RETAKE_DEPTH


func _prompt(t: Dictionary) -> String:
	if t.ours:
		return ""
	if _wet(t):
		return "Creeper holds this tower. Clear it off first."
	if t.capturing:
		return "Capturing Aether Tower... %d%%  (stay close)" % roundi(t.progress / Config.AETHER_CAPTURE_TIME * 100.0)
	return "[%s] Capture Aether Tower (+%.0f Aether/min)" % [Keybinds.short("use"), Config.AETHER_TOWER_RATE * 60.0]


func update(dt: float) -> void:
	var op = op_pos.call()
	for t in towers:
		if t.ours:
			_hold(t, dt)
		elif t.capturing:
			_capture(t, dt, op)
		var spin: float = 0.3 if not t.ours else 1.2
		(t.crystal as Node3D).rotation.y += dt * spin


func _capture(t: Dictionary, dt: float, op) -> void:
	var near: bool = op != null and Vector2(op.x - t.pos.x, op.z - t.pos.z).length() <= Config.AETHER_CAPTURE_RANGE + 1.5
	if not near or _wet(t):
		t.capturing = false
		t.progress = 0.0
		t.bar.visible = false
		Bus.say("Uplink broken: %s." % ("creeper on the tower" if near else "Operative left"), "warn")
		return
	t.progress += dt
	t.bar.visible = true
	t.bar.set_value(t.progress / Config.AETHER_CAPTURE_TIME, Color("d38cff"))
	if t.progress >= Config.AETHER_CAPTURE_TIME:
		_set_owner(t, true)
		world.effects.burst(t.pos + Vector3(0, 4, 0), Color("d38cff"), 3.0, 0.5)
		Sfx.play("good")
		Bus.say("Aether Tower captured: +%.0f Aether/min while you hold it." % (Config.AETHER_TOWER_RATE * 60.0), "good")


func _hold(t: Dictionary, dt: float) -> void:
	Upgrades.trickle(Config.AETHER_TOWER_RATE * dt)
	if _wet(t):
		t.lost += dt
		t.bar.visible = true
		t.bar.set_value(1.0 - t.lost / Config.AETHER_RETAKE_TIME, Color("ff5a4a"))
		if t.lost >= Config.AETHER_RETAKE_TIME:
			_set_owner(t, false)
			Sfx.play("lost", t.pos)
			Bus.say("The creeper retook an Aether Tower. Send the Operative to win it back.", "bad")
	else:
		t.lost = maxf(0.0, t.lost - dt)
		t.bar.visible = t.lost > 0.0
		t.bar.set_value(1.0 - t.lost / Config.AETHER_RETAKE_TIME, Color("ff5a4a"))


func _set_owner(t: Dictionary, ours: bool) -> void:
	t.ours = ours
	t.capturing = false
	t.progress = 0.0
	t.lost = 0.0
	t.bar.visible = false
	var c := OURS if ours else ENEMY
	(t.crystal as MeshInstance3D).material_override = StructureMeshes.mat(c, 0.1, 0.2, Color("b060ff") if ours else c, 3.0 if ours else 1.2)
