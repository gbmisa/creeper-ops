class_name SmokeCastles2bLeftovers
## Stage 21b P8 leftovers:
##  - the enemy builder skips bailey cells of a bailey you took (EnemyBuildPlan._pad);
##  - the portcullis tweens up when its ring changes hands to you, down on retake;
##  - the castle2 debug spots: gate from the open side, tower pitched up.
## Level 1 Ashmoat approach screenshots: not run (no display); Opus judges visuals.


static func run(g) -> void:
	var castles: Strongholds = g.castles
	var c: Dictionary = castles.list[0]  # Ashmoat: concentric, hostile again after the siege smoke
	var lay: Dictionary = castles.lays[c.id]
	_bailey_skip(g, castles, c, lay)
	_portcullis(g, castles, c, lay)
	_spots(g, castles, c, lay)


## Ward cells phantom-occupied: with the bailey taken _pad must find nothing; with the
## bailey hostile it must pick a bailey cell. Phantoms are erased right after.
static func _bailey_skip(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var b = g.structures.enemy_build
	var phantoms := []
	for wc in lay.ward:
		var ph := { "alive": true, "cell": wc }
		(b as EnemyBuilder).list.append(ph)
		phantoms.append(ph)
	c.stage = 2  # bailey taken, castle still the enemy's
	var skipped: Vector2i = EnemyBuildPlan._pad(b, c)
	var skip_ok: bool = skipped.x < 0 or not (lay.bailey as Array).has(skipped)
	c.stage = 0
	var picked: Vector2i = EnemyBuildPlan._pad(b, c)
	var pick_ok: bool = picked.x >= 0 and (lay.bailey as Array).has(picked)
	for ph in phantoms:
		(b as EnemyBuilder).list.erase(ph)
	SmokeTest._check("castles2b leftovers: the enemy builder skips a taken bailey",
		skip_ok and pick_ok, "(taken %s, hostile %s)" % [skipped, picked])


## The gate mesh target height follows the ring's owner through set_stage (which is what
## the game calls on every handoff); the smoke reads the target, not the tween.
static func _portcullis(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var v: Dictionary = castles.views[c.id]
	var outer := -1
	var inner := -1
	for i in (lay.gates as Array).size():
		if str((lay.gates[i] as Dictionary).get("ring", "outer")) == "inner" and inner < 0:
			inner = i
		elif outer < 0:
			outer = i
	CastleStages.set_stage(castles, c, 0)
	var n0 := v.gates[outer] as Node3D
	var base: float = n0.get_meta("base_y")
	var low_ok := absf(float(n0.get_meta("lift_t")) - base) < 0.01
	CastleStages.set_stage(castles, c, 1)  # gate stage taken: the outer ring is yours
	var want := base + CastleDefs.PORTCULLIS_LIFT
	var high_ok := absf(float(n0.get_meta("lift_t")) - want) < 0.01
	var inner_ok := true
	if inner >= 0:
		var ni := v.gates[inner] as Node3D
		inner_ok = absf(float(ni.get_meta("lift_t")) - float(ni.get_meta("base_y"))) < 0.01
	CastleStages.set_stage(castles, c, 0)  # retaken: back down
	var back_ok := absf(float(n0.get_meta("lift_t")) - base) < 0.01
	SmokeTest._check("castles2b leftovers: the portcullis rises on the gate stage, lowers on retake",
		low_ok and high_ok and inner_ok and back_ok,
		"(lift %.2f, want %.2f)" % [float(n0.get_meta("lift_t")), want])


## The gate spot lands on open, gate-level ground on the axis; the tower spot pitches up.
static func _spots(g, castles: Strongholds, c: Dictionary, lay: Dictionary) -> void:
	var grid: Grid = g.surface.grid
	var g0: Dictionary = lay.gates[0]
	var gate: Vector2i = g0.cells[0]
	var dir: Vector2i = (g0.outer.back() - gate).sign()
	var spot: Vector2i = CastleDebug._open_approach(grid, gate, dir)
	var gy := grid.height_at(gate.x, gate.y)
	var spot_ok := grid.in_bounds(spot.x, spot.y) \
		and absf(grid.height_at(spot.x, spot.y) - gy) <= 1.0 \
		and not bool(grid.blocked[grid.idx(spot.x, spot.y)])
	SmokeTest._check("castles2b leftovers: the gate spot is on the open side",
		spot_ok, "(%s)" % spot)
	SmokeTest._check("castles2b leftovers: the tower spot pitches up, the roof spot down",
		CastleDebug.pitch_for("tower") > 0.3 and CastleDebug.pitch_for("roof") < 0.0
		and is_equal_approx(CastleDebug.pitch_for("gate"), 0.05))
