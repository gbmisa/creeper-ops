class_name CastleRaids
extends RefCounted
## Stage 7b: castle stakes. Both sides prize castles, and holding many becomes a liability.
##  - Reprisal: taking a castle starts a `reprisal_warn` countdown, then the nest nearest it
##    sends one gathered group (the "big raid") with mission "castle".
##  - Sieges: every held castle draws a smaller raid each siege interval, with `siege_warn`
##    seconds of warning. The interval shrinks with aggression and the number held.
##  - Hostile castles feed nests: each nest within `nest_buff_range` cells of an enemy-owned
##    castle spawns `nest_buff` faster per castle (SporeNests reads nest.rate); a castle you
##    hold slows the hives near it (CastlePerks.hive_factor).
## Size = (base + per_tier * tier) * aggression * stack, stack = 1 + held_stack * (held - 1).
## Rules: Config.CASTLE_RULES merged with the level's CASTLE_RULES. Per-castle state lives in
## c.raid (plain data, saved with Strongholds.state()). Tier stands in for 8a's pressure.

const KIND_LABEL := { "reprisal": "Reprisal raid", "siege": "Siege" }

var castles: Strongholds
var nests: SporeNests
var rules: Dictionary
var launched := 0  # raids sent this mission (sim report)


func _init(s: Strongholds, level_rules: Dictionary) -> void:
	castles = s
	nests = s.nests
	rules = Config.CASTLE_RULES.merged(level_rules, true)
	for c in s.list:
		c["raid"] = { "kind": "", "warn": 0.0, "next": 0.0, "source": "", "last": c.state }
		_add_markers(c)
	s.world.updaters.append(update)


## 1 with one castle held; each extra castle adds held_stack.
func stack() -> float:
	return 1.0 + rules.held_stack * maxi(0, castles.held() - 1)


func size(kind: String) -> int:
	var base: float = rules[kind + "_base"] + rules[kind + "_per_tier"] * nests.tier
	return maxi(1, roundi(base * rules.aggression * stack()))


## Seconds between sieges on each held castle.
func interval() -> float:
	return maxf(Config.CASTLE_SIEGE_MIN, rules.siege_interval / (rules.aggression * stack()))


func update(dt: float) -> void:
	for c in castles.list:
		var r: Dictionary = c.raid
		var was: String = r.last
		r.last = c.state
		if c.state == "hostile" or c.state == "capturing":
			r.kind = ""  # lost or never held: nothing to raid
			r.grace = false
			continue
		if was == "hostile" or was == "capturing":
			r.grace = true  # safe from retake until the reprisal launches
			_warn(c, "reprisal", rules.reprisal_warn)
			continue
		if r.kind != "":
			r.warn -= dt
			if r.warn <= 0.0:
				_launch(c)
			continue
		r.next -= dt
		if r.next <= rules.siege_warn:
			_warn(c, "siege", maxf(0.0, r.next))
	_buff_nests()


func _warn(c: Dictionary, kind: String, secs: float) -> void:
	var r: Dictionary = c.raid
	var src := _source(c)
	r.kind = kind
	r.warn = secs
	r.source = src.get("name", "")
	if src.is_empty():
		return
	Sfx.play("alarm")
	Bus.say("%s: the %s nest is gathering a %s (~%d raiders). It marches in %ds. Buy turrets (Castle tab), move Snipers and units, or hold the capture point." \
		% [c.name, src.name, KIND_LABEL[kind].to_lower(), size(kind), ceili(secs)], "bad")


func _launch(c: Dictionary) -> void:
	var r: Dictionary = c.raid
	var kind: String = r.kind
	r.kind = ""
	if kind == "reprisal":
		r.grace = false
	r.next = interval()
	var src := _source(c)
	if src.is_empty():
		return
	var n := size(kind)
	var gid := RaiderGroups.spawn(nests.raiders, src, RaiderGroups.compose(n, nests.pressure(), launched + int(src.get("x", 0))), "castle")
	var sent := 0
	if gid >= 0:
		for m in nests.raiders.list:
			if int(m.get("group", -1)) == gid:
				sent += 1
	launched += 1
	Sfx.play("alarm")
	Bus.say("%s: %d raiders from the %s nest are marching on it." % [KIND_LABEL[kind], sent, src.name], "bad")


## The nest the raid comes from: the one already named if it still lives, else the nearest.
func _source(c: Dictionary) -> Dictionary:
	var live := nests.nests.filter(func(n): return n.alive)
	if live.is_empty():
		return {}
	for n in live:
		if n.name == c.raid.source:
			return n
	var centre := Vector2(castles.lays[c.id].spire.centre)
	live.sort_custom(func(a, b): return centre.distance_to(Vector2(a.x, a.z)) < centre.distance_to(Vector2(b.x, b.z)))
	return live[0]


func _buff_nests() -> void:
	for n in nests.nests:
		var k := 0
		for c in castles.list:
			var centre := Vector2(castles.lays[c.id].spire.centre)
			if c.owner == "enemy" and centre.distance_to(Vector2(n.x, n.z)) <= rules.nest_buff_range:
				k += 1
		n["rate"] = (1.0 + rules.nest_buff * k) * CastlePerks.hive_factor(castles, Vector2(n.x, n.z))  # held castles ward nearby hives


func _add_markers(c: Dictionary) -> void:
	var w := castles.world
	var centre: Vector2i = castles.lays[c.id].spire.centre
	var top := w.grid.cell_ground(centre.x, centre.y) + Vector3(0, 3.0, 0)
	w.markers.append({ "pos": top, "color": Color("ff5a4a"),
		"label": func(): return "%s in %ds" % [KIND_LABEL.get(c.raid.kind, ""), ceili(c.raid.warn)],
		"visible": func(): return c.raid.kind != "" })
	var m := { "pos": top, "color": Color("ff8a4a"),
		"label": func(): return "Gathering: %d → %s" % [size(c.raid.kind), c.name] if c.raid.kind != "" else "" }
	m["visible"] = func():  # follows the source nest
		if c.raid.kind == "":
			return false
		var src := _source(c)
		if src.is_empty():
			return false
		m.pos = src.pos + Vector3(0, 6.5, 0)  # above the nest's own label
		return true
	w.markers.append(m)
