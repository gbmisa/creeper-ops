class_name FlyerLaunch
## Roost parts and flocks (Stage 19). A hive grows a Roost at FLYER_ROOST_P (the first flyer
## unlock; the spec's "stage 2" is pressure 0.70 after the Stage 8 rebalance, too late for
## bats). Each grown Roost launches a flock every interval scaled by pressure. When the Node
## is sealed (SporeNests.seal at MORTAR_SEAL) every Roost also launches a flock at the Node.
## Killing the Roost stops that hive's flyers.

static var enabled := true  # debug: --noflyers


## Called from Hives.tick for an active hive: grow the Roost once pressure allows.
static func sync(host, hive: Dictionary) -> void:
	if not enabled:
		return
	if host.pressure() < Config.FLYER_ROOST_P:
		return
	for part in hive.parts:
		if str(part.id) == "roost":
			return  # alive, or killed (stays dead until the hive is rebuilt)
	var p := HiveParts.spawn(host, hive, "roost", 1, false)
	p.cd = Config.FLYER_FIRST_DELAY


static func interval(host, hive: Dictionary) -> float:
	return lerpf(Config.FLYER_INTERVAL_START, Config.FLYER_INTERVAL_MIN, host.pressure()) / float(hive.get("rate", 1.0))


## Per frame: count down every grown Roost and launch.
static func tick(host, dt: float) -> void:
	var sealed: bool = float(host.seal) >= Config.MORTAR_SEAL
	for h in host.nests:
		var hive: Dictionary = h
		if str(hive.state) != "active":
			continue
		var roost := Hives.find(hive, "roost")
		if roost.is_empty() or not roost.grown:
			continue
		if not sealed:
			hive["sealed_t"] = -1.0
		roost.cd = float(roost.cd) - dt
		if sealed:
			var last: float = float(hive.get("sealed_t", -1.0))
			if last < 0.0 or host.flyers.time - last >= Config.FLYER_SEAL_REPEAT:
				hive["sealed_t"] = host.flyers.time
				launch(host, hive, roost, true)
				roost.cd = interval(host, hive)
				continue
		if float(roost.cd) <= 0.0:
			launch(host, hive, roost, false)
			roost.cd = interval(host, hive)


## One flock from a Roost. Returns how many flyers appeared.
static func launch(host, hive: Dictionary, roost: Dictionary, at_node: bool, row := {}) -> int:
	var fl: Flyers = host.flyers
	if row.is_empty():
		row = FlyerDefs.pick(host.pressure(), randf())
	if row.is_empty():
		return 0
	var span: Array = row.flock
	var n: int = mini(randi_range(int(span[0]), int(span[1])), Config.FLYER_MAX - fl.count())
	var base: Vector3 = roost.pos + Vector3(0, 3.0, 0)
	for i in n:
		var a := randf() * TAU
		fl.spawn(row, base + Vector3(cos(a), 0, sin(a)) * 1.5, { "node_bias": at_node, "home": roost.pos,
			"cd": 1.0 + randf() * 1.5 })
	if n > 0:
		Sfx.play("screech", base)
		Sfx.play("flap", base)
		Bus.say("%s%s launch from %s." % ["%d " % n if n > 1 else "A ", row.name + ("s" if n > 1 else ""), hive.name], "warn")
	return n


## Debug: `--flyers=TYPE,N` (bat | gasbag | wyvern) spawns N near the Command Node.
static func demo(g, spec: String) -> void:
	var parts := spec.split(",")
	var want := parts[0].to_lower()
	var n := int(parts[1]) if parts.size() > 1 else 4
	var row: Dictionary = FlyerDefs.ROWS[0]
	for r in FlyerDefs.ROWS:
		if str(r.name).to_lower().contains(want):
			row = r
	var node: Structure = g.structures.command_node()
	var base: Vector3 = node.pos if node != null else Vector3(80, 0, 80)
	var ctl = g.fps.controller if g.fps.world != null else null
	for i in n:
		var a := float(i) / maxf(1.0, float(n)) * TAU
		var p := base + Vector3(cos(a) * 14.0, 0, sin(a) * 14.0)
		if ctl != null:  # first person: a ring ahead of the Operative, so a shot shows them
			var ahead := Vector3(-sin(ctl.yaw), 0, -cos(ctl.yaw))
			p = ctl.pos + ahead * 18.0 + ahead.cross(Vector3.UP) * (float(i) - float(n - 1) * 0.5) * 6.0
			p.y = g.surface.grid.smooth_y(p.x, p.z) + float(row.alt) * 0.6
		if ctl == null:
			p.y = g.surface.grid.smooth_y(p.x, p.z) + float(row.alt)
		g.hazards.nests.flyers.spawn(row, p, { "home": base })
