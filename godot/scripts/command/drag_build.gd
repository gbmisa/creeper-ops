class_name DragBuild
## Click-and-drag building with a structure tool armed.
## Collectors and Relays lay a CHAIN from the press cell toward the cursor: each piece sits as
## far along the line as its link allows from the previous one (backing off when that cell is
## a cliff, occupied or wet), so the chain stays connected. Everything else lays a ROW of
## buildings side by side. plan() is the preview; commit() places them in order, so each new
## (unfinished) relay extends the network for the next.

const MAX := 48  # = the terrain shader's plan array


static func is_chain(type: String) -> bool:
	return type == "collector" or type == "relay"


## [{ cell: Vector2i, ok: bool, cost: int }] from cell a (press) toward cell b (cursor).
static func plan(cm: CommandMode, a: Vector2i, b: Vector2i) -> Array[Dictionary]:
	return plan_at(cm.structures, cm.tool, a, b)


## Same plan, for the Operative's build mode (it has no CommandMode).
static func plan_at(structures, type: String, a: Vector2i, b: Vector2i) -> Array[Dictionary]:
	var def: Dictionary = StructureDefs.DEFS[type]
	var cells := _chain(structures, type, a, b) if is_chain(type) else _row(type, a, b)
	var out: Array[Dictionary] = []
	var planned: Array[Vector3] = []  # earlier ok pieces that will relay: (x, z, link)
	for c in cells:
		var ok: bool = Placement.can_place(structures, type, c.x, c.y, planned).ok
		out.append({ "cell": c, "ok": ok, "cost": int(def.get("cost", 0)) })
		if ok and def.get("relays", false):
			planned.append(Vector3(c.x, c.y, def.link))
	return out


## Places every ok piece in order. Returns how many were placed.
static func commit(cm: CommandMode, items: Array[Dictionary]) -> int:
	return commit_at(cm.structures, cm.tool, items)


static func commit_at(structures, type: String, items: Array[Dictionary]) -> int:
	var n := 0
	var why := ""
	for it in items:
		var c: Vector2i = it.cell
		var res := Placement.can_place(structures, type, c.x, c.y)
		if res.ok:
			structures.place(type, c.x, c.y)
			n += 1
		elif why == "":
			why = res.reason
	if n > 0:
		Sfx.play("click")
	else:
		Sfx.play("deny")
	if n < items.size():
		Bus.say("Placed %d of %d. %s" % [n, items.size(), why], "warn")
	return n


## HUD line. Cost is the sum of def.cost over pieces that can actually be placed.
static func summary(items: Array[Dictionary]) -> String:
	var ok := 0
	var cost := 0
	for it in items:
		if it.ok:
			ok += 1
			cost += int(it.get("cost", 0))
	var line := "Release to place %d: %d energy total" % [ok, cost]
	if ok != items.size():
		line += " (%d blocked)" % (items.size() - ok)
	return line


## Chain: walk the press->cursor line; each step takes the farthest cell on the line that is
## within link of the previous piece and has buildable ground. A short last hop to the cursor
## is only added when it covers at least half a link.
static func _chain(structures, type: String, a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = [a]
	var d := Vector2(b - a)
	var length := d.length()
	if length < 1.0:
		return out
	var dir := d / length
	var link: float = StructureDefs.DEFS[type].link
	var prev := a
	var along := 0.0
	while out.size() < MAX and length - along >= link * 0.5:
		var found := false
		var s := minf(along + link, length)
		while s >= along + 1.0:
			var p := Vector2(a) + dir * s
			var c := Vector2i(roundi(p.x), roundi(p.y))
			if c != prev and Vector2(c - prev).length() <= link and Placement.ground_reason(structures, type, c.x, c.y) == "":
				out.append(c)
				prev = c
				along = s
				found = true
				break
			s -= 0.5
		if not found:  # nothing buildable within reach: show the ideal spot as blocked and stop
			var p := Vector2(a) + dir * minf(along + link, length)
			out.append(Vector2i(roundi(p.x), roundi(p.y)))
			break
	return out


## Row: footprints touching edge to edge along the drag (Chebyshev steps of one width).
static func _row(type: String, a: Vector2i, b: Vector2i) -> Array[Vector2i]:
	var w := StructureDefs.footprint(type) * 2 + 1
	var d := Vector2(b - a)
	var cheb := maxf(absf(d.x), absf(d.y))
	var out: Array[Vector2i] = [a]
	if cheb < w:
		return out
	var dir := d / cheb
	for k in range(1, mini(MAX, floori(cheb / w) + 1)):
		var p := Vector2(a) + dir * float(k * w)
		out.append(Vector2i(roundi(p.x), roundi(p.y)))
	return out
