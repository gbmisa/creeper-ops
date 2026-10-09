class_name SmokeCastles2BaileyUx
## Bailey-standard UX (Gregory's playtest): the castle marker used to float over the crown
## nest at every stage, so players walked to the heart and shot it while the real objective
## (gate hall, bailey standard) was somewhere else. Checks the marker now tracks the current
## stage's objective, and that live trebuchets get findable markers while they block the bailey.


static func run(g) -> void:
	var r := SmokeCastles2Capture.rig(g)
	var w: World = r.w
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	var grid: Grid = r.w.grid
	var cname: String = c.name

	var mark := _castle_marker(w, cname)
	SmokeTest._check("bailey ux: castle marker exists", not mark.is_empty())
	# Gate stage: marker at the gate hall, not the crown.
	var gate_mid: Vector2i = lay.zones["gate"].cells[lay.zones["gate"].cells.size() / 2]
	var gate_p := grid.cell_ground(gate_mid.x, gate_mid.y)
	var crown_p: Vector3 = castles.views[c.id].crown.position
	var pos: Vector3 = mark.pos.call()
	SmokeTest._check("bailey ux: gate-stage marker at the gate hall", pos.distance_to(gate_p) < 12.0,
		"%.1fm" % pos.distance_to(gate_p))
	SmokeTest._check("bailey ux: gate-stage marker not at the crown", pos.distance_to(crown_p) > 12.0,
		"%.1fm" % pos.distance_to(crown_p))

	# Bailey stage: marker at the standard, text names the trebuchet blocker.
	CastleStages.set_stage(castles, c, 1)
	var std_p := grid.cell_ground(lay.home.x, lay.home.y)
	pos = mark.pos.call()
	SmokeTest._check("bailey ux: bailey-stage marker at the standard", pos.distance_to(std_p) < 12.0,
		"%.1fm" % pos.distance_to(std_p))
	var text: String = mark.label.call()
	SmokeTest._check("bailey ux: bailey marker names the trebuchet blocker", "trebuchet" in text.to_lower(), text)
	# Trebuchet markers: one visible per live engine, only during the bailey stage.
	var n_engines := CastleEngines.alive_count(c)
	SmokeTest._check("bailey ux: trebuchet markers visible while they block", _treb_visible(w) == n_engines and n_engines > 0,
		"%d visible, %d alive" % [_treb_visible(w), n_engines])
	# Blocker still works: standing in the zone with trebuchets up gains nothing.
	_put(r.op, grid, lay.zones.bailey.cells[4])
	_sim(castles, 3.0)
	SmokeTest._check("bailey ux: trebuchets still block the standard", c.stage == 1 and c.ring.progress == 0.0)

	# Engines down: trebuchet markers vanish, the hold advances the stage.
	for e in c.engines:
		e.hp = 0.0
	SmokeTest._check("bailey ux: trebuchet markers gone when engines are down", _treb_visible(w) == 0)
	_sim(castles, CastleDefs.BAILEY_TIME + 0.3)
	SmokeTest._check("bailey ux: holding the standard takes the bailey", c.stage == 2)
	SmokeTest._check("bailey ux: trebuchet markers gone after the bailey falls", _treb_visible(w) == 0)

	# Keep stage: marker back at the crown, where the damageable objective is.
	pos = mark.pos.call()
	SmokeTest._check("bailey ux: keep-stage marker at the crown", pos.distance_to(crown_p) < 12.0,
		"%.1fm" % pos.distance_to(crown_p))


static func _castle_marker(w: World, cname: String) -> Dictionary:
	for m in w.markers:
		if m.label is Callable and str(m.label.call()).begins_with(cname):
			return m
	return {}


static func _treb_visible(w: World) -> int:
	var n := 0
	for m in w.markers:
		if not (m.label is String) or m.label != "Trebuchet":
			continue
		if m.visible.call():
			n += 1
	return n


static func _put(op: PlayerController, grid: Grid, cell: Vector2i) -> void:
	op.pos = grid.cell_center(cell.x, cell.y)


static func _sim(castles: Strongholds, seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		castles.update(0.1)
		t += 0.1
