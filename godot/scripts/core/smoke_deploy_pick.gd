class_name SmokeDeployPick
## Deploy-site pick: several Totems -> choose one; single site is immediate; respawn timeout uses last-used.


static func run(g) -> void:
	for s in g.structures.beacons():
		g.structures.remove(s)
	g.flow.to_command("")
	g.teleport_cooldown = 0.0
	g.command.select_structure(null)
	var grid: Grid = g.level.grid
	var t: Array[Structure] = []
	var o := SmokeDeploy._line(grid, 30)
	for i in 3:
		var b: Structure = g.structures.place("beacon", o.x + i * 10, o.y, true)
		if b != null:
			t.append(b)
	SmokeTest._check("pick: 3 totems placed", t.size() == 3 and g.structures.beacons().size() == 3)
	if t.size() < 3:
		return
	g.command.select_structure(null)
	g.structures.selected_beacon = null
	var pick: DeployPick = g.deploy.pick
	g.deploy.deploy_totem()
	SmokeTest._check("pick: opens with 3 sites, no spawn", pick.active and g.mode == "command" and pick.sites.size() == 3)
	pick.hover = 1
	SmokeTest._check("pick: hover highlights", pick.highlighted() == 1 and ">>" in pick.label(1) and ">>" not in pick.label(0))
	pick.choose(t[1])
	SmokeTest._check("pick: not active after choose", not pick.active)
	SmokeTest._check("pick: operative at 2nd totem", g.mode == "surface" and _near(g, t[1]) and not _near(g, t[0]))
	SmokeTest._check("pick: markers cleaned", g.surface.markers.filter(func(m): return m.has("pick")).is_empty())
	g.flow.to_command("")
	# Last used is the default next time.
	g.deploy.deploy_totem()
	SmokeTest._check("pick: default is last used", pick.active and pick.highlighted() == 1)
	pick.cancel()
	SmokeTest._check("pick: cancel stays aboard", not pick.active and g.mode == "command")
	# A selected Totem deploys directly.
	g.command.select_structure(t[2])
	g.deploy.deploy_totem()
	SmokeTest._check("pick: selected totem deploys directly", not pick.active and g.mode == "surface" and _near(g, t[2]))
	g.flow.to_command("")
	g.command.select_structure(null)
	# Respawn pick times out to the last-used site (t[2]).
	pick.begin_respawn()
	SmokeTest._check("pick: respawn opens", pick.active and pick.respawn)
	pick.update(Config.RESPAWN_PICK_TIME + 0.5)
	SmokeTest._check("pick: respawn timeout -> last used", not pick.active and g.mode == "surface" and _near(g, t[2]))
	g.flow.to_command("")
	# One site: immediate.
	g.structures.remove(t[0])
	g.structures.remove(t[1])
	g.structures.selected_beacon = null
	g.deploy.deploy_totem()
	SmokeTest._check("pick: single site deploys immediately", not pick.active and g.mode == "surface" and _near(g, t[2]))
	g.flow.to_command("")


static func _near(g, b: Structure) -> bool:
	var p: Vector3 = g.fps.controller.pos
	return Vector2(p.x - b.pos.x, p.z - b.pos.z).length() < 4.0
