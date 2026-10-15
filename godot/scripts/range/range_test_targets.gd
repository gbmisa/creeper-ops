class_name RangeTestTargets
## Phase 3 checks: target counts, dummy behind plywood / brick, armor station, plate reset, paper marks, hit log.

static func run(t: RangeTest) -> void:
	var targets := RangeTargets.new()
	t.add_child(targets)
	await t.get_tree().physics_frame
	await t.get_tree().physics_frame
	t.check("targets: 6 plates, 2 paper, 9 dummies",
		targets.plates.size() == 6 and targets.papers.size() == 2 and targets.dummies.size() == 9, str(targets.dummies.size()))
	var ply: RangeDummy = targets.wall_dummies["plywood"]
	t._fly("762_ps", Vector3(ply.position.x, 1.3, 0), Vector3(0, 0, -1))
	var hit_ok: bool = not t._hits.is_empty() and t._hits[0]["zone"] == "thorax" and t._hits[0]["result"] == "PEN" and ply.body.hp["thorax"] < 85.0
	t.check("dummy behind plywood is hit through the panel", hit_ok)
	var brick: RangeDummy = targets.wall_dummies["brick"]
	t._fly("762_ps", Vector3(brick.position.x, 1.3, 0), Vector3(0, 0, -1))
	t.check("dummy behind brick is protected from PS", t._hits.is_empty() and brick.body.hp["thorax"] == 85.0)
	var d: RangeDummy = targets.dummies[0]
	RangeBench.cycle_armor(targets, 3)
	t.check("armor station: class 6 + helmet on every dummy", targets.loadout == 3 and targets.dummies.all(func(x): return x.body.armor.get("thorax", {}).get("id", "") == "steel6" and x.body.armor.get("head", {}).get("id", "") == "helmet3"))
	var r := d.body.shoot("thorax", {"dmg": 57.0, "pen": 35.0, "armor_dmg": 0.52, "glance": 90.0})
	t.check("armored dummy: shot reports armor durability", r["armor_dur"] >= 0.0 and r["armor_dur"] < 80.0 and r["result"] in ["PEN", "BLOCKED"])
	RangeBench.cycle_armor(targets, 4)
	t.check("armor station wraps to no armor and resets hp", targets.loadout == 0 and d.body.armor.is_empty() and ply.body.hp["thorax"] == 85.0)
	d.kill()
	var dead: bool = d.body.dead
	d.respawn()
	t.check("dummy dies and respawns at full health", dead and d.body.alive() and d.body.hp["head"] == 35.0)
	var x0 := targets.mover.position.x
	targets.mover._process(1.0)
	t.check("moving target moves along its rail", absf(targets.mover.position.x - x0) > 1.0)
	var pl := targets.plates[2]
	var line := targets.on_impact({"pos": pl.global_position + Vector3(0, -0.1, 0.02), "kind": "stop", "ammo": "762_ps"})
	var swung := pl.swinging
	pl.reset()
	t.check("steel plate swings on impact and resets", line.begins_with("Steel plate 50 m") and swung and not pl.swinging and pl.rotation_degrees.x == 0.0, line)
	var paper := targets.papers[0]
	var pline := targets.on_impact({"pos": paper.global_position + Vector3(0, 1.3, 0), "kind": "pass", "ammo": "762_ps"})
	var marked: bool = paper.marks.size() == 1 and paper.zone_hits.get("thorax", 0) == 1
	paper.reset()
	t.check("paper silhouette keeps a zone mark until reset", marked and pline.contains("thorax") and paper.marks.is_empty(), pline)
	var hl := RangeHitLog.new()
	t.add_child(hl)
	for i in 12:
		hl.add("line %d" % i)
	var txt := RangeHitLog.format({"owner": d, "zone": "head", "dist": 15.2, "dmg": 34.4, "result": "BLOCKED", "armor_dur": 41.0, "killed": false})
	t.check("hit log keeps the last 8 hits", hl.lines.size() == 8 and hl.lines[0] == "line 4" and hl.lines[7] == "line 11")
	t.check("hit log line shows target, zone, dmg, verdict, armor", txt.contains("Dummy") and txt.contains("head") and txt.contains("34 dmg") and txt.contains("BLOCKED") and txt.contains("armor 41"), txt)
