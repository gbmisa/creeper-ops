class_name SmokeBaileyAllCastles
## Bailey capture path on EVERY concentric castle (L1 Ashmoat + all L2): the
## bailey stage must activate, trebuchets must be registered and killable, the
## standard zone must exist and accept holds, and completing the hold must
## advance to the keep stage. Regression for "taking the bailey doesn't work".

static func _castle(g, lvl_num: int, cid: String) -> Dictionary:
	var lvl: Dictionary = Level01.build() if lvl_num == 1 else Level02.build()
	var w := World.new()
	w.setup("L%d%s" % [lvl_num, cid], lvl.grid, false)
	g.add_child(w)
	var nests := SporeNests.new(w, lvl.nests, lvl.raid_schedule)
	var castles := Strongholds.new(w, lvl.castles, nests)
	var c: Dictionary = castles.list.filter(func(x): return x.id == cid)[0]
	var op := PlayerController.new(null)
	castles.op = func(): return op
	for x in castles.list:
		x.garrison_timer = -1e6  # no garrison: raiders only where a test puts them
	return { "w": w, "castles": castles, "c": c, "lay": castles.lays[cid],
		"grid": w.grid, "op": op }

static func run(g) -> void:
	for spec in [[1, "ashmoat"], [2, "ashgate"], [2, "thornwall"], [2, "crown"], [2, "northreach"], [2, "stormcrown"]]:
		_check_castle(g, spec[0], spec[1])

static func _check_castle(g, lvl_num: int, cid: String) -> void:
	var r := _castle(g, lvl_num, cid)
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var lay: Dictionary = r.lay
	var grid: Grid = r.grid
	var op: PlayerController = r.op
	var w: World = r.w
	var tag := "bailey all " + cid

	var stages: Array = lay.stages
	SmokeTest._check(tag + ": stages are gate/bailey/keep", stages == ["gate", "bailey", "keep"], str(stages))
	var bz: Dictionary = lay.zones["bailey"]
	SmokeTest._check(tag + ": bailey zone exists with 9 cells", bz.cells.size() == 9, "cells=%d" % bz.cells.size())
	var std: Vector2i = bz.cells[4]
	op.pos = grid.cell_center(std.x, std.y)
	SmokeTest._check(tag + ": in_zone(bailey) at standard", StrongholdRules.in_zone(lay, op.pos, "bailey"),
		"cell=%s" % str(std))
	SmokeTest._check(tag + ": engines registered", c.engines.size() > 0, "n=%d" % c.engines.size())

	# Gate hold -> bailey stage.
	var hall: Vector2i = lay.zones["gate"].cells[4]
	op.pos = grid.cell_center(hall.x, hall.y)
	var t := 0.0
	while c.stage == 0 and t < 60.0:
		castles.update(0.5)
		t += 0.5
	SmokeTest._check(tag + ": gate hold advances to bailey stage", c.stage == 1, "stage=%d" % c.stage)

	# Trebuchets block the hold.
	op.pos = grid.cell_center(std.x, std.y)
	t = 0.0
	while t < 20.0:
		castles.update(0.5)
		t += 0.5
	SmokeTest._check(tag + ": trebuchets block the hold", c.stage == 1 and c.ring.progress < 0.01,
		"stage=%d alive=%d progress=%.2f" % [c.stage, CastleEngines.alive_count(c), c.ring.progress])

	# Kill all trebuchets, hold the standard -> keep stage.
	for e in c.engines:
		e.hp = 0.0
	t = 0.0
	while c.stage == 1 and t < 60.0:
		castles.update(0.5)
		t += 0.5
	SmokeTest._check(tag + ": standard hold takes the bailey", c.stage == 2, "stage=%d" % c.stage)
	w.queue_free()
