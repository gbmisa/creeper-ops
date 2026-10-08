class_name SmokeCastleBuild
## Building in castle courtyards (only while you hold the castle; a retake destroys what you
## built there), the solid crown nest and point-blank rifle hits. Called from SmokeStrongholds.


static func run(g) -> void:
	var castles: Strongholds = g.castles
	var sm = g.structures
	var c: Dictionary = castles.list[1]
	var lay: Dictionary = castles.lays[c.id]
	var spot := _free_yard_cell(g.surface.grid, lay, sm)
	var why := Placement._ground_rules(sm, "relay", spot.x, spot.y, null)
	SmokeTest._check("castle: hostile courtyard is not buildable", why.begins_with("Enemy castle"), "(%s)" % why)
	StrongholdRules.to_held(g.surface, c, lay)
	why = Placement._ground_rules(sm, "relay", spot.x, spot.y, null)
	SmokeTest._check("castle: held courtyard is buildable", why == "", "(%s at %s)" % [why, spot])
	var relay: Structure = sm.place("relay", spot.x, spot.y, true)
	StrongholdRules.to_hostile(g.surface, c, lay, 1.0)
	castles.on_lost.call(lay.courtyard)
	SmokeTest._check("castle: a retake destroys courtyard structures", relay.dead)
	StrongholdMeshes.refresh(castles.views[c.id], c)
	_crown(castles, c)
	_garrison_exits(g, castles, c, lay)


static func _crown(castles: Strongholds, c: Dictionary) -> void:
	var cp: Vector3 = (castles.views[c.id].crown as Node3D).position
	var o := { "pos": cp + Vector3(0.1, 0.0, 0.0) }
	StrongholdRules.crown_push(castles.views[c.id], o)
	SmokeTest._check("crown nest is solid", Vector2(o.pos.x - cp.x, o.pos.z - cp.z).length() >= Config.CROWN_RADIUS)
	var t := OperativeWeapons.ray_sphere(cp, Vector3.FORWARD, cp, 1.9)
	SmokeTest._check("rifle hits a target point-blank (muzzle inside it)", t < 1.0, "(t %s)" % t)


static func _free_yard_cell(grid: Grid, lay: Dictionary, sm) -> Vector2i:
	for cell in lay.courtyard:
		var ok := true
		for f in Placement.footprint_cells("relay", cell.x, cell.y):
			var i := grid.idx(f.x, f.y)
			ok = ok and grid.yard[i] == 1 and grid.material[i] == Grid.Mat.NATURAL and not sm.occupied.has(i)
		if ok:
			return cell
	return lay.courtyard[0]


## A garrison raider chasing prey outside its raised castle leaves by the gate and bridge
## instead of pressing into the wall beside the gate (playtest bug at High Bastion).
static func _garrison_exits(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var raiders: Raiders = castles.nests.raiders
	var grid: Grid = g.surface.grid
	var n: int = lay.rect.size.x
	var out := CastleShape._at(lay.rect, lay.gates[0].side, n / 2 + 6, -7)  # off to the side: a straight line hits the wall
	var bait := Node3D.new()
	g.surface.add_child(bait)
	bait.position = grid.cell_ground(out.x, out.y)
	var prey := { "node": bait, "radius": 0.6, "alive": func(): return true, "hit": func(_d): pass }
	var v: Dictionary = castles.views[c.id]
	raiders.spawn(v.garrison, RaiderDefs.named("Skitter"), true)
	var r: Dictionary = raiders.list.back()
	var start := grid.world_to_cell(r.node.position.x, r.node.position.z)
	for i in 600:  # 30 s
		raiders.update(0.05, [prey], [out])
	var p: Vector3 = r.node.position
	var reached := Vector2(p.x - bait.position.x, p.z - bait.position.z).length() < 4.0
	SmokeTest._check("castle: garrison walks out of the gate to its prey", reached,
		"(from %s to %s, target %s)" % [start, grid.world_to_cell(p.x, p.z), out])
	raiders.kill(r)
	bait.queue_free()
