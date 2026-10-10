class_name SalvageEngines
extends RefCounted
## Salvage Engines (Stage 9b, STRONGHOLDS_DESIGN 5.1 as built). Placed in level data
## (`engines`); the Operative hooks a socket from first person (EngineHook). A hooked socket is a
## network leaf: it launches Salvage return packets at EngineDefs.RATE from the engine's reserve,
## along the cable to the nearest connected relaying structure and home.
## Pauses: creeper over the socket's cell (wet), a live hive named in `hive`, a castle named in
## `castle` that you do not hold. A hook is not prey; only losing its anchor relay unhooks it.
## Saveable state per engine: reserve + each socket's hooked/acc (state()/load_state()).

var world: World
var structures: StructureManager
var stockpile: Stockpile
var cash_mode := false            # cave: no network, a hooked engine pays out by hand once
var operative := func() -> Variant: return null  # Vector3 feet or null (hint only)
var list: Array[Dictionary] = []
var shipped := 0.0
var _hinted := {}
var _t := 0.0


func _init(w: World, rows: Array, mgr: StructureManager, stock: Stockpile) -> void:
	world = w
	structures = mgr
	stockpile = stock
	for raw in rows:
		list.append(_build(raw))
	w.updaters.append(tick)


func _build(row: Dictionary) -> Dictionary:
	var k := EngineDefs.kind(row)
	var e := { "row": row, "id": str(row.id), "name": str(k.name), "reserve": EngineDefs.reserve_of(row),
		"max": EngineDefs.reserve_of(row), "sockets": [] }
	var root := EngineMeshes.model(row)
	world.add_child(root)
	e["root"] = root
	for raw in row.sockets:
		var s: Dictionary = (raw as Dictionary).duplicate()
		var vis := EngineMeshes.socket(world, s.pos)
		s["node"] = vis.node
		s["mat"] = vis.mat
		s["hooked"] = false
		s["acc"] = 0.0
		s["anchor"] = null
		s["cable"] = null
		s["bead"] = null
		e.sockets.append(s)
	var centre := Vector3((int(row.x) + 0.5) * Config.CELL, float(row.floor + k.top) * Config.LEVEL_H + 1.2, (int(row.z) + 0.5) * Config.CELL)
	world.markers.append({ "pos": centre, "color": Color("ffb347"), "minor": true,
		"label": func(): return label(e), "visible": func(): return true })
	for s in e.sockets:
		EngineHook.register(self, e, s)
		tint(s)
	return e


func hooked_count(e: Dictionary) -> int:
	return (e.sockets as Array).filter(func(s): return s.hooked).size()


func total_hooked() -> int:
	var n := 0
	for e in list:
		n += hooked_count(e)
	return n


func salvage_left() -> float:
	var n := 0.0
	for e in list:
		n += float(e.reserve)
	return n


func label(e: Dictionary) -> String:
	var text := "Salvage Engine %d/%d hooked, %d left" % [hooked_count(e), e.sockets.size(), int(ceil(float(e.reserve)))]
	if float(e.reserve) <= 0.0:
		return "Salvage Engine (spent)"
	return text


func is_wet(s: Dictionary) -> bool:
	return world.creeper.depth_at(s.cell.x, s.cell.y) > Config.MIN_DEPTH


## Nearest built, connected, relaying structure within EngineDefs.LINK cells of the socket.
func anchor_for(s: Dictionary) -> Structure:
	var best: Structure = null
	var bd := EngineDefs.LINK
	var p: Vector3 = s.pos
	for m in structures.list:
		if m.dead or m.is_flying() or not m.is_built() or not m.connected or not m.def.get("relays", false):
			continue
		var d := Vector2(m.pos.x - p.x, m.pos.z - p.z).length() / Config.CELL
		if d <= bd:
			bd = d
			best = m
	return best


func hook(e: Dictionary, s: Dictionary) -> bool:
	if s.hooked or float(e.reserve) <= 0.0:
		return false
	if cash_mode:
		return EngineHook.cash(self, e, s)
	var a := anchor_for(s)
	if a == null:
		return false
	s.hooked = true
	s.anchor = a
	s.acc = 0.0
	EngineHook.link(self, s, a)
	world.effects.burst(s.pos, EngineMeshes.HOOKED, 1.4, 0.4)
	Sfx.play("good", s.pos)
	Bus.say("%s hooked (%d/%d sockets)." % [e.name, hooked_count(e), e.sockets.size()], "good")
	return true


func unhook(s: Dictionary, why: String) -> void:
	if not s.hooked:
		return
	s.hooked = false
	s.anchor = null
	EngineHook.unlink(s)
	world.effects.burst(s.pos, Color("ff6a3a"), 1.4, 0.4)
	Sfx.play("boom", s.pos)
	Bus.say("Salvage Engine socket unhooked: %s. Go back and hook it again." % why, "warn")


func tick(dt: float) -> void:
	_t += dt
	for e in list:
		var idle := float(e.reserve) <= 0.0
		for s in e.sockets:
			if s.hooked and not cash_mode:
				_ship(e, s, dt, idle)
			EngineHook.animate(self, e, s, _t)
	_hint()


func _ship(e: Dictionary, s: Dictionary, dt: float, idle: bool) -> void:
	var a: Structure = s.anchor
	if a != null and a.dead:
		unhook(s, "relay lost")  # the only way a hook ends
		return
	if a == null or not a.connected or a.is_flying():
		a = anchor_for(s)  # lost its route or took off: cable to another relay in reach, if any
		s.anchor = a
		EngineHook.link(self, s, a)
	if idle or a == null or is_wet(s):
		return
	s.acc += dt
	if s.acc < EngineDefs.RATE:
		return
	var route := structures.network.route(a)
	if route.is_empty():
		return
	route.reverse()
	route.insert(0, s.pos)
	if structures.packets.launch_route(route, "salvage", 1.0):
		s.acc -= EngineDefs.RATE
		e.reserve = maxf(0.0, float(e.reserve) - 1.0)
		shipped += 1.0
		if float(e.reserve) <= 0.0:
			Bus.say("%s is spent." % e.name, "warn")
			for q in e.sockets:
				tint(q)


## A brief hint, once, when an unhooked engine comes within reach of the network.
func _hint() -> void:
	if cash_mode or int(_t * 2.0) % 4 != 0:
		return
	for e in list:
		if _hinted.has(e.id) or float(e.reserve) <= 0.0:
			continue
		for s in e.sockets:
			if not s.hooked and anchor_for(s) != null:
				_hinted[e.id] = true
				Bus.say("%s is in reach of the network: deploy the Operative and hold %s at a glowing socket." % [e.name, Keybinds.short("use")], "radio")
				break


func tint(s: Dictionary) -> void:
	var spent := false
	for e in list:
		if (e.sockets as Array).has(s):
			spent = float(e.reserve) <= 0.0
	var c: Color = EngineMeshes.DEAD if spent else (EngineMeshes.HOOKED if s.hooked else EngineMeshes.FREE)
	EngineMeshes.tint(s, c, 0.1 if spent else (2.2 if s.hooked else 1.3))


func state() -> Array:
	return list.map(func(e): return { "id": e.id, "reserve": e.reserve,
		"sockets": e.sockets.map(func(s): return { "hooked": s.hooked, "acc": s.acc }) })


func load_state(rows: Array) -> void:
	for d in rows:
		for e in list:
			if e.id != str(d.id):
				continue
			e.reserve = float(d.reserve)
			for i in mini(e.sockets.size(), (d.sockets as Array).size()):
				var s: Dictionary = e.sockets[i]
				var ds: Dictionary = d.sockets[i]
				s.hooked = bool(ds.hooked)
				s.acc = float(ds.acc)
				if s.hooked:
					s.anchor = anchor_for(s)
					EngineHook.link(self, s, s.anchor)
				tint(s)
