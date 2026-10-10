class_name EnemyRangeView
## Command mode: click an enemy artillery piece to see its reach on the ground (outer ring at
## its range, inner ring at its minimum range), and see the same rings while a build tool's
## ghost sits inside a live piece's reach. Drawn as terrain shader tints (`enemy_rings`).
## Selection is plain data on CommandMode.enemy_sel = { src, castle (id), i }.
## To add enemy mortars later: add one row to `sources()` returning the same dict shape.

const PICK_M := 3.0   # click tolerance around the piece, metres
const SLOTS := 8      # enemy_rings[] size in terrain.gdshader


## Live, firing pieces as { src, castle (id), name, i, pos, range, min, hp, max_hp, label } in metres.
static func sources(castles: Strongholds) -> Array:
	var out := []
	if castles == null:
		return out
	for c in castles.list:
		var v: Dictionary = castles.views.get(c.id, {})
		if v.get("engines", []).size() != c.get("engines", []).size() or not CastleEngines.active(c):
			continue
		for i in c.engines.size():
			var e: Dictionary = c.engines[i]
			if not CastleEngines.alive(e):
				continue
			var p: Vector3 = (v.engines[i] as Node3D).position
			out.append({ "src": "treb", "castle": c.id, "name": c.name, "i": i, "pos": p, "label": "Trebuchet",
				"range": float(e.get("range", CastleDefs.ENGINE.range)) * Config.CELL,
				"min": CastleDefs.ENGINE.min_range * Config.CELL, "hp": e.hp, "max_hp": e.max_hp })
	return out


## The live piece nearest `point` (within PICK_M), or {}.
static func pick(castles: Strongholds, point: Vector3) -> Dictionary:
	var best := {}
	var bd := PICK_M
	for s in sources(castles):
		var d := Vector2(s.pos.x - point.x, s.pos.z - point.z).length()
		if d <= bd:
			bd = d
			best = s
	return best


static func _find(castles: Strongholds, sel: Dictionary) -> Dictionary:
	for s in sources(castles):
		if s.src == sel.src and s.castle == sel.castle and s.i == sel.i:
			return s
	return {}


## Left-click hook (tool unarmed). True when it selected a piece.
static func click(cm: CommandMode) -> bool:
	var s := pick(cm.castles, cm.hover.point)
	if s.is_empty():
		return false
	cm.units.select([])
	cm.select_structure(null)  # clears enemy_sel and any structure selection
	cm.enemy_sel = { "src": s.src, "castle": s.castle, "i": s.i }
	Sfx.play("click")
	Bus.selection_changed.emit()
	return true


## Ring vectors (xy, radius m, on) for the current selection plus every piece covering the ghost.
static func rings(cm: CommandMode) -> Array[Vector4]:
	var out: Array[Vector4] = []
	if not cm.enemy_sel.is_empty():
		var s := _find(cm.castles, cm.enemy_sel)
		if s.is_empty():
			cm.enemy_sel = {}  # destroyed or gone inactive
			Bus.selection_changed.emit()
		else:
			_add(out, s)
	if _building(cm) and not cm.hover.is_empty():
		for s in covering(cm.castles, cm.hover.point):
			_add(out, s)
	return out


static func _add(out: Array[Vector4], s: Dictionary) -> void:
	out.append(Vector4(s.pos.x, s.pos.z, s.range, 1.0))
	out.append(Vector4(s.pos.x, s.pos.z, s.min, 1.0))


static func _building(cm: CommandMode) -> bool:
	return cm.tool != "" and not cm.tool.begins_with("@")


## Live pieces whose ring band (min..range) contains `point`.
static func covering(castles: Strongholds, point: Vector3) -> Array:
	return sources(castles).filter(func(s):
		var d := Vector2(s.pos.x - point.x, s.pos.z - point.z).length()
		return d <= s.range and d >= s.min)


## Per-frame hook: writes the shader slots (zeros when nothing to show).
static func update(cm: CommandMode) -> void:
	var packed := PackedVector4Array()
	for r in rings(cm).slice(0, SLOTS):
		packed.append(r)
	packed.resize(SLOTS)
	cm.world.terrain_mat.set_shader_parameter("enemy_rings", packed)


## Placement hint: append a trebuchet-range warning (never blocks).
static func hint(cm: CommandMode, text: String) -> String:
	if not _building(cm) or cm.hover.is_empty() or covering(cm.castles, cm.hover.point).is_empty():
		return text
	var w := "In trebuchet range"
	return w if text == "" else "%s. %s" % [text, w]


## Info panel content for the selected piece, or {} (title, frac, hp_text, body).
static func info(cm: CommandMode) -> Dictionary:
	if cm.enemy_sel.is_empty():
		return {}
	var s := _find(cm.castles, cm.enemy_sel)
	if s.is_empty():
		return {}
	return { "title": s.label, "frac": clampf(s.hp / s.max_hp, 0.0, 1.0), "hp": "HP %d / %d" % [ceili(s.hp), roundi(s.max_hp)],
		"body": "%s\nRange %d cells (min %d)" % [s.name, roundi(s.range / Config.CELL), roundi(s.min / Config.CELL)] }
