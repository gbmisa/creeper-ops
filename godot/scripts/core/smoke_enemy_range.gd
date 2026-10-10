class_name SmokeEnemyRange
## Command-mode trebuchet reach view: click-pick, ring values, clear on deselect, dead engines.


static func run(g) -> void:
	var r := SmokeCastles2Capture.rig(g)
	var castles: Strongholds = r.castles
	var c: Dictionary = r.c
	var v: Dictionary = castles.views[c.id]
	var cm := CommandMode.new()
	cm.castles = castles
	cm.world = r.w
	var node: Node3D = v.engines[0]
	var near: Vector3 = node.position + Vector3(1.0, 0, 0.5)
	var s := EnemyRangeView.pick(castles, near)
	SmokeTest._check("enemy range: click near a trebuchet picks it", not s.is_empty() and s.castle == c.id and s.i == 0)
	SmokeTest._check("enemy range: far from any engine picks nothing", EnemyRangeView.pick(castles, node.position + Vector3(0, 0, 200)).is_empty())
	cm.enemy_sel = { "src": s.src, "castle": s.castle, "i": s.i }
	var rg := EnemyRangeView.rings(cm)
	var want: float = float(c.engines[0].range) * Config.CELL
	SmokeTest._check("enemy range: outer ring = range, inner ring = min range", rg.size() == 2
		and is_equal_approx(rg[0].z, want) and is_equal_approx(rg[1].z, CastleDefs.ENGINE.min_range * Config.CELL)
		and is_equal_approx(rg[0].x, node.position.x))
	EnemyRangeView.update(cm)
	var packed: PackedVector4Array = r.w.terrain_mat.get_shader_parameter("enemy_rings")
	SmokeTest._check("enemy range: shader slots carry the rings", packed.size() == 8 and is_equal_approx(packed[0].z, want) and packed[0].w == 1.0)
	cm.select_structure(null)
	EnemyRangeView.update(cm)
	packed = r.w.terrain_mat.get_shader_parameter("enemy_rings")
	SmokeTest._check("enemy range: cleared on deselect", cm.enemy_sel.is_empty() and packed[0].w == 0.0)
	cm.tool = "wall"
	cm.hover = { "point": node.position + Vector3((want + CastleDefs.ENGINE.min_range * Config.CELL) * 0.5, 0, 0) }
	SmokeTest._check("enemy range: armed tool in reach shows rings and a hint", EnemyRangeView.rings(cm).size() == 2 and "trebuchet" in EnemyRangeView.hint(cm, ""))
	cm.hover = { "point": node.position + Vector3(want * 2.0, 0, 0) }
	SmokeTest._check("enemy range: out of reach shows nothing", EnemyRangeView.rings(cm).is_empty() and EnemyRangeView.hint(cm, "") == "")
	c.engines[0].hp = 0.0
	SmokeTest._check("enemy range: a dead engine is not selectable", EnemyRangeView.pick(castles, near).is_empty())
	cm.free()
