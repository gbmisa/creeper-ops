class_name WeaponLogic
## Active behaviour for built, connected, landed weapons. Every shot spends ammo, and ammo
## only arrives as packets. Targets by def.targets: "creeper", "air" (Beam: surface-to-air,
## burns flying enemies), "raiders" (Snipers), "siege" (Trebuchet: enemy structures, hive
## parts, enemy mortars — never creeper). Hold-fire (CW3 toggle) skips firing entirely.
## Mortar splash also nicks raiders for MORTAR_RAIDER_DMG. Snipers are the anti-raider weapon.
## Creeper removal follows CW3 (CreeperStrike): cannons spread `hits` over a disk, mortars and
## Bertha hit every wet cell in theirs. A `roams` weapon (Thor) also fires in flight.


static func update(s: Structure, dt: float, mgr) -> void:
	s.firing = maxf(0.0, s.firing - dt)
	if not s.def.has("fire_rate") or s.hold_fire:
		return
	s.cooldown -= dt
	if s.cooldown > 0.0 or s.ammo < s.per_shot():
		return
	var fired := false
	match s.type:
		"cannon", "thor":
			fired = _zap(s, mgr)
		"mortar", "bertha":
			fired = _lob(s, mgr)
		"trebuchet":
			fired = _trebuchet(s, mgr)
		"beam":
			fired = _beam(s, mgr)
		"sniper":
			fired = _snipe(s, mgr)
	# Only reset the cooldown when a shot happened, so idle weapons react instantly.
	if fired:
		s.ammo -= s.per_shot()
		s.cooldown = fire_interval(s)
		s.firing = fire_interval(s) + 1.5


## Forge-adjusted stats.
static func fire_interval(s: Structure) -> float:
	return s.def.fire_rate / Upgrades.mult("fire_rate")


## Held castles reach (Stage 21 CastlePerks.attach sets this for the live game).
static var range_bonus := func(_s: Structure) -> float: return 1.0


static func range_cells(s: Structure) -> float:
	return def_range(s.def) * range_bonus.call(s)


## Range in cells for a def (placement previews, before the structure exists).
static func def_range(def: Dictionary) -> float:
	return def.get("range", 0.0) * Upgrades.mult("range")


## How far a Nullifier reaches to its emitter: a weapon range, so Fire Range extends it.
static func nullify_range() -> float:
	return def_range(StructureDefs.DEFS.nullifier)


static func _muzzle(s: Structure) -> Vector3:
	return s.node.position + Vector3(0, s.def.link_y, 0)


## Where shot effects start: the model's "Muzzle" (visual only; rules use _muzzle).
static func _fx(s: Structure) -> Vector3:
	var m := s.body.find_child("Muzzle", true, false) as Node3D
	return m.global_position if m and m.is_inside_tree() else _muzzle(s)


static func _aim(s: Structure, target: Vector3) -> void:
	var tur := s.body.get_node_or_null("Turret") as Node3D
	if tur:
		var d := target - s.node.position
		tur.rotation.y = atan2(-d.z, d.x)
		var arm := tur.get_node_or_null("Arm") as Node3D
		if arm:  # visual pitch: dip toward near/low targets, rear up for lobs
			var lob := s.type == "mortar" or s.type == "bertha"
			var flat := Vector2(d.x, d.z).length()
			arm.rotation.z = 0.12 if lob else clampf(atan2(d.y - 3.0, flat) * 0.5, -0.3, 0.15)


## The cell a weapon fires from: where it is now, even mid-flight.
static func _cell(s: Structure, w: World) -> Vector2i:
	return w.grid.world_to_cell(s.pos.x, s.pos.z) if s.is_flying() else Vector2i(s.x, s.z)


static func _zap(s: Structure, mgr) -> bool:
	var w: World = mgr.world
	var at := _cell(s, w)
	var t = w.creeper.nearest_wet(at.x, at.y, range_cells(s))
	if t == null:
		return false
	CreeperStrike.hits(w.creeper, t.x, t.y, s.def.splash, s.def.hits, s.def.power)
	var b := w.grid.cell_ground(t.x, t.y) + Vector3(0, w.creeper.depth_at(t.x, t.y), 0)
	_aim(s, b)
	var col := Color("7fe0ff") if s.type == "thor" else Color("fff27a")
	w.effects.beam(_fx(s), b, col, 0.07, 0.08)
	w.effects.burst(b, Color("fff6b0"), 0.6, 0.12)
	Sfx.play("blaster", s.pos)
	WeaponFx.fire(s, w.effects)  # P1: recoil + muzzle flash (visual only)
	return true


static func _lob(s: Structure, mgr) -> bool:
	var w: World = mgr.world
	var at := _cell(s, w)
	var t = w.creeper.deepest_wet(at.x, at.y, range_cells(s), w.grid.height_at(at.x, at.y),
		Config.LOB_RANGE_PER_LEVEL, s.def.get("min_range", 0))
	if t == null:
		return false
	var b := w.grid.cell_ground(t.x, t.y) + Vector3(0, w.creeper.depth_at(t.x, t.y), 0)
	_aim(s, b)
	var big := s.type == "bertha"
	var splash: float = s.def.splash
	var power: float = s.def.power
	w.effects.lob(_fx(s), b, { "color": Color("ffb347"), "time": 2.2 if big else 1.0, "arc": 30.0 if big else 10.0,
		"size": 0.8 if big else 0.45, "on_arrive": func():
			CreeperStrike.disk(w.creeper, t.x, t.y, splash, power)
			WeaponLogic._splash_raiders(mgr, b, splash)
			WeaponLogic._splash_builds(mgr, b, splash, big)
			w.effects.burst(b, Color("ffaa33"), splash * Config.CELL * 0.7, 0.45)
			Sfx.play("boom", b) })
	Sfx.play("mortar", s.pos)
	WeaponFx.fire(s, w.effects)  # P1: recoil + muzzle flash (visual only)
	return true


## Player Trebuchet (castle_only): lobs a stone at the nearest enemy structure, hive
## part or enemy mortar inside [min_range, range]. Never at creeper: the blast damages
## enemy builds, not the sim. The arm swing is CastleEngineMeshes.throw (visual).
static func _trebuchet(s: Structure, mgr) -> bool:
	var w: World = mgr.world
	var reach: float = range_cells(s) * Config.CELL
	var min_r := float(s.def.get("min_range", 0.0)) * Config.CELL
	var from: Vector3 = s.node.position
	var best: Dictionary = {}
	var bd := reach
	for foe in _siege_foes(mgr):
		if not (foe.alive as Callable).call():
			continue
		var mp: Vector3 = (foe.node as Node3D).position
		var d := Vector2(mp.x - from.x, mp.z - from.z).length()
		if d < min_r or d > reach or d >= bd:
			continue
		bd = d
		best = foe
	if best.is_empty():
		return false
	var target: Vector3 = (best.node as Node3D).position
	var tn := s.body.get_node_or_null("Trebuchet") as Node3D
	if tn != null:
		CastleEngineMeshes.throw(tn, target)
	var splash := float(s.def.splash)
	var power := float(s.def.power)
	w.effects.lob(_fx(s), target, { "color": Color("c8b089"), "time": 2.2, "arc": 26.0, "size": 0.7,
		"on_arrive": func(): _treb_impact(mgr, target, splash, power) })
	Sfx.play("mortar", s.pos)
	return true


## Every enemy build the Trebuchet may hit: built enemy structures (hub mortars die
## with their parent), hive parts except the core (Operative/Lance-only), hive mortars.
static func _siege_foes(mgr) -> Array:
	var out: Array = []
	if mgr.enemy_build != null:
		for raw in (mgr.enemy_build as EnemyBuilder).list:
			var e: Dictionary = raw
			var foe: Dictionary = e.get("enemy", {})
			if bool(e.alive) and bool(e.get("grown", true)) and not foe.is_empty():
				out.append(foe)
	if mgr.hazards == null:
		return out
	for n in (mgr.hazards as SurfaceHazards).nests.nests:
		var hive: Dictionary = n
		if not bool(hive.alive):
			continue
		for raw in hive.get("parts", []):
			var p: Dictionary = raw
			var foe: Dictionary = p.get("enemy", {})
			if bool(p.alive) and str(p.get("kind", "")) != "core" and not foe.is_empty():
				out.append(foe)
		for raw in hive.get("mortars", []):
			var m: Dictionary = raw
			var foe: Dictionary = m.get("enemy", {})
			if bool(m.alive) and not foe.is_empty():
				out.append(foe)
	return out


## The stone lands: enemy builds in the blast take power (the Core ignores it, as with
## every non-Operative weapon); raiders in the blast take the mortar's flat nick.
static func _treb_impact(mgr, at: Vector3, splash: float, power: float) -> void:
	var w: World = mgr.world
	w.effects.burst(at + Vector3.UP * 0.5, Color("c8b089"), splash * Config.CELL, 0.5)
	Sfx.play("boom", at)
	var r := splash * Config.CELL
	if mgr.enemy_build != null:
		(mgr.enemy_build as EnemyBuilder).splash(at, r, power)
	_splash_raiders(mgr, at, splash)
	if mgr.hazards == null:
		return
	for n in (mgr.hazards as SurfaceHazards).nests.nests:
		var hive: Dictionary = n
		if not bool(hive.alive):
			continue
		for raw in (hive.get("parts", []) as Array) + (hive.get("mortars", []) as Array):
			var p: Dictionary = raw
			var foe: Dictionary = p.get("enemy", {})
			if foe.is_empty() or not (foe.alive as Callable).call():
				continue
			var mp: Vector3 = (foe.node as Node3D).position
			if Vector2(mp.x - at.x, mp.z - at.z).length() <= r + float(foe.get("radius", 0.5)):
				(foe.hit as Callable).call(power)


## Beam: surface-to-air. Burns flying enemies: hostile lobs first (spore volleys, then
## spitter acid globs), then Flyers. Ground raiders are left to Snipers. One zap per
## firing cycle: a beam swatting spit is not also hitting something else that tick.
static func _beam(s: Structure, mgr) -> bool:
	var w: World = mgr.world
	var a := _muzzle(s)
	var reach: float = range_cells(s) * Config.CELL
	for it in w.effects.lobs():
		if (it.pos as Vector3).distance_to(a) > reach:
			continue
		if it.has("spore"):
			it.spore_hp -= s.def.power
			_aim(s, it.pos)
			w.effects.beam(_fx(s), it.pos, Color("ff5050"), 0.06, 0.07)
			if it.spore_hp <= 0.0:
				it.dead = true
				w.effects.burst(it.pos, Color("88ff55"), 2.5, 0.4)
				Sfx.play("pop", it.pos)
			Sfx.play("beam", s.pos)
			WeaponFx.fire(s, w.effects)  # P1: recoil + muzzle flash (visual only)
			return true
		if it.get("foe", false):
			# Spitter acid glob: one zap pops it mid-flight; its on_arrive never fires.
			# Friendly lobs (player mortar/bertha shells) carry no "foe" key and are ignored.
			_aim(s, it.pos)
			w.effects.beam(_fx(s), it.pos, Color("ff5050"), 0.06, 0.07)
			it.dead = true
			w.effects.burst(it.pos, Color("d6ff3a"), 2.0, 0.3)
			Sfx.play("pop", it.pos)
			Sfx.play("beam", s.pos)
			WeaponFx.fire(s, w.effects)  # P1: recoil + muzzle flash (visual only)
			return true
	var fp = Flyers.strike(w, a, reach, s.def.power)  # Stage 19: flyers
	if fp != null:
		_aim(s, fp)
		w.effects.beam(_fx(s), fp, Color("ff5050"), 0.06, 0.07)
		Sfx.play("beam", s.pos)
		WeaponFx.fire(s, w.effects)  # P1: recoil + muzzle flash (visual only)
		return true
	return false


## Flat nick so a mortar stays a weak secondary against raiders. Uses their hit/kill path.
static func _splash_raiders(mgr, at: Vector3, splash: float) -> void:
	if mgr.hazards == null:
		return
	var reach := splash * Config.CELL
	for m in mgr.hazards.nests.raiders.list.duplicate():
		if not m.alive:
			continue
		var p: Vector3 = m.node.position
		if Vector2(p.x - at.x, p.z - at.z).length() <= reach:
			m.enemy.hit.call(Config.MORTAR_RAIDER_DMG)


static func _splash_builds(mgr, at: Vector3, splash: float, big: bool) -> void:
	if mgr.enemy_build == null:
		return
	var dmg := EnemyStructures.SHELL_BERTHA if big else EnemyStructures.SHELL_MORTAR
	mgr.enemy_build.splash(at, splash * Config.CELL, dmg)


## Line of sight over terrain and castle roofs: true when nothing solid sits between a and b.
static func sees(grid: Grid, a: Vector3, b: Vector3) -> bool:
	var d := a.distance_to(b)
	if d < 0.01:
		return true
	var hit: Variant = grid.raycast(a, (b - a) / d, d)
	return hit == null or (hit as Vector3).distance_to(a) >= d - Config.SNIPER_LOS_SLACK


## Where a lobbed arc (effects.lob from a to b with apex `arc`) first enters solid
## ground or a castle roof slab; b itself when the arc is clear. Lets acid and spit
## splash on keep walls instead of passing through them. Low arcs over low walls
## still clear. Fire-time only: 12 short raycasts.
static func clip_lob(grid: Grid, a: Vector3, b: Vector3, arc: float) -> Vector3:
	var prev := a
	var n := 12
	for i in range(1, n + 1):
		var t := float(i) / n
		var p := a.lerp(b, t)
		p.y += sin(t * PI) * arc
		var d := prev.distance_to(p)
		if d > 0.01:
			var hit: Variant = grid.raycast(prev, (p - prev) / d, d)
			if hit != null:
				var hp := hit as Vector3
				# The target stands on the ground: a hit at the very end of the arc
				# is the impact itself, not a blocker.
				if i == n and hp.distance_to(b) <= Config.SNIPER_LOS_SLACK:
					return b
				return hp
		prev = p
	return b


static func _snipe(s: Structure, mgr) -> bool:
	if mgr.hazards == null:
		return false
	var w: World = mgr.world
	var a := _muzzle(s)
	var reach: float = range_cells(s) * Config.CELL
	var best: Dictionary = {}
	var bd := reach
	var foes: Array = mgr.hazards.nests.raiders.list.duplicate()
	if mgr.hazards.guards:
		foes.append_array(mgr.hazards.guards.foes())  # Sentinels, if the range allows
	if mgr.enemy_build != null:
		foes.append_array(mgr.enemy_build.snipe_foes())
	var best_ranged := false
	var p := Vector3.ZERO
	for m in foes:
		# Stage 9b rule change: range is measured on the ground, like the enemy ranged weapons it answers
		# (a Spitter on the flat used to out-reach a Sniper standing a mesa above it).
		var mp: Vector3 = m.node.position
		var d := Vector2(mp.x - a.x, mp.z - a.z).length()
		if d >= reach:
			continue
		# Stage 9b rule change: a Sniper shoots ranged raiders (Spitter, Lancer) in range before nearer
		# melee ones; otherwise it is the nearest foe as before.
		var ranged: bool = str((m.get("tier", {}) as Dictionary).get("role", "")) == "ranged"
		if not (best.is_empty() or (ranged and not best_ranged) or (ranged == best_ranged and d < bd)):
			continue
		# Playtest 1: only what it can see. Terrain, castle walls and roofs block the shot.
		var at: Vector3 = mp + Vector3(0, float(m.get("oy", 1.0)), 0)
		if not sees(w.grid, a, at):
			continue
		bd = d
		best = m
		best_ranged = ranged
		p = at
	if best.is_empty():
		s.cooldown = Config.SNIPER_LOS_RETRY  # nothing in sight: look again shortly, not every frame
		return false
	_aim(s, p)
	w.effects.beam(_fx(s), p, Color("e0f0ff"), 0.08, 0.05)
	var grade := AmmoGrades.take_shot(s)
	AmmoGrades.shoot(best.enemy, s.def.power, grade, w, p)
	Sfx.play("rifle", s.pos)
	WeaponFx.fire(s, w.effects)  # P1: recoil + muzzle flash (visual only)
	return true
