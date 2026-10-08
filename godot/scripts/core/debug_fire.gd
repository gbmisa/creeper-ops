class_name DebugFire
## --fire=rifle|crossbow|sprayer|rocket[,lead]|hurt (with --autostart): holds the Operative's trigger from
## 0.9 s so a --shot screenshot catches the weapon mid-action. Sprayer and rifle get a pool of
## creeper / a post to hit in front of the Operative.


static func run(g, spec: String) -> void:
	var parts := spec.split(",")
	var kind := parts[0]
	var lead := float(parts[1]) if parts.size() > 1 else 0.0  # fire this many seconds before the shot
	var hint: Vector2i = g.level.landing_hint  # dry ground at the base, facing north
	DebugHooks._drop(g, hint.x, hint.y - 4, 0.0)
	g.get_tree().create_timer(0.8 if kind == "sprayer" else 1.43 - lead).timeout.connect(func():
		if g.fps.world == null:
			return
		var w: OperativeWeapons = g.fps.weapons
		var ctrl: PlayerController = g.fps.controller
		var fwd := ctrl.forward()
		if kind == "hurt":  # a big blow from the right and a kill confirm, for the overlay screenshot
			HitFeel.note_source(ctrl.pos + Vector3(fwd.z, 0, -fwd.x) * -10.0 + fwd * 4.0)
			g.fps.damage(25.0)
			w.feel.confirm(true)
			return
		var grid: Grid = g.fps.world.grid
		if kind in ["sprayer", "rifle", "crossbow"]:
			var ahead := ctrl.pos + fwd * (9.0 if kind == "sprayer" else 25.0)
			var c := grid.world_to_cell(ahead.x, ahead.z)
			for cell in grid.cells_in_radius(c.x, c.y, 1.6 if kind == "sprayer" else 1.0):
				g.fps.world.creeper.set_depth(cell.x, cell.y, 2.5)
		ctrl.pitch = -0.03 if kind in ["rifle", "crossbow"] else -0.12
		w.current = kind
		w.debug_trigger = true)
