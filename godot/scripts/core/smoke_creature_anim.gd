class_name SmokeCreatureAnim
## ART3 track A checks: CreatureAnim runtime with zero .glb files (procedural fallback
## everywhere) plus the clip/death logic on a hand-built animated node. Called from
## SmokeTest.run. Must not depend on what earlier smoke files left behind.


static func run(g) -> void:
	_model_awareness(g)
	_anim_logic(g)
	_raider_kill_path(g)


## CreatureAnim.make returns an animated node exactly when the .glb exists,
## null otherwise (procedural fallback). This invariant holds with and without
## model files present, so the checks pass on a bare checkout and on the
## art/3-integration branch alike.
static func _model_awareness(g) -> void:
	var ok := true
	for id in CreatureGallery.IDS:
		var has_glb := ResourceLoader.exists(CreatureAnim.MODEL_DIR + id + ".glb")
		var n := CreatureAnim.make(id, 1.0, null)
		var got := n != null
		if got != has_glb or (got and _has_player(n)) != has_glb:
			ok = false
		if n != null:
			n.queue_free()
	SmokeTest._check("creature anim: make matches .glb presence", ok)
	SmokeTest._check("creature anim: empty id -> null", CreatureAnim.make("", 1.0, null) == null)

	ok = true
	for tier in RaiderDefs.ROWS:
		var want := ResourceLoader.exists(CreatureAnim.MODEL_DIR + CreatureAnim.id_of(str(tier.get("name", ""))) + ".glb")
		var n := RaiderMeshes.make(tier)
		if n == null or _has_player(n) != want:
			ok = false
		n.queue_free()
	var sent := RaiderMeshes.make({ "name": "Sentinel", "size": 1.0, "color": Color("d04aff") })
	if sent == null or _has_player(sent) != ResourceLoader.exists(CreatureAnim.MODEL_DIR + "sentinel.glb"):
		ok = false
	sent.queue_free()
	SmokeTest._check("creature anim: raider mesh matches .glb presence", ok)

	ok = true
	for row in FlyerDefs.ROWS:
		var want := ResourceLoader.exists(CreatureAnim.MODEL_DIR + CreatureAnim.id_of(str(row.get("name", ""))) + ".glb")
		var n := FlyerMeshes.make(row)
		if n == null or _has_player(n) != want:
			ok = false
		n.queue_free()
	SmokeTest._check("creature anim: flyer mesh matches .glb presence", ok)

	var s := UnitMeshes.make("soldier")
	var c := UnitMeshes.make("crawler")
	ok = s != null and c != null \
		and _has_player(s) == ResourceLoader.exists(CreatureAnim.MODEL_DIR + "soldier.glb") \
		and _has_player(c) == ResourceLoader.exists(CreatureAnim.MODEL_DIR + "crawler.glb")
	s.queue_free()
	c.queue_free()
	SmokeTest._check("creature anim: unit mesh matches .glb presence", ok)

	var core := HiveMeshes.part("core")
	SmokeTest._check("creature anim: hive core matches .glb presence",
		core != null and _has_player(core) == ResourceLoader.exists(CreatureAnim.MODEL_DIR + "hive_core.glb"))
	core.queue_free()

	# move/attack/hit drive the player when one exists, no-op otherwise.
	var p := RaiderMeshes.make(RaiderDefs.named("Skitter"))
	var p_want := ResourceLoader.exists(CreatureAnim.MODEL_DIR + "skitter.glb")
	CreatureAnim.move(p, 3.0)
	CreatureAnim.attack(p)
	CreatureAnim.hit(p)
	var pp := _find_player(p)
	ok = (pp != null) == p_want
	if pp != null:
		ok = ok and pp.current_animation == "hit"
	SmokeTest._check("creature anim: hooks drive player or no-op", ok)
	p.queue_free()

	# Trebuchet: animated .glb when present, procedural fallback otherwise.
	var treb := CastleEngineMeshes.trebuchet()
	var treb_want := ResourceLoader.exists(CreatureAnim.MODEL_DIR + "trebuchet.glb")
	ok = treb != null and treb.name == "Trebuchet" and (_find_player(treb) != null) == treb_want
	CastleEngineMeshes.throw(treb, treb.position + Vector3(10, 0, 0))
	var tp := _find_player(treb)
	if treb_want:
		ok = ok and tp != null and tp.current_animation == "attack"
	SmokeTest._check("creature anim: trebuchet model + throw clip", ok)
	treb.queue_free()


static func _has_player(n: Node) -> bool:
	return _find_player(n) != null


static func _find_player(n: Node) -> AnimationPlayer:
	var found := n.find_children("*", "AnimationPlayer", true, false)
	return found[0] as AnimationPlayer if not found.is_empty() else null


## Clip blend and death-delay logic on a hand-built animated node (no .glb needed:
## exercises the same wrap path make() uses).
static func _anim_logic(g) -> void:
	var glow := StandardMaterial3D.new()
	var node := Node3D.new()
	g.add_child(node)  # in the tree: die() can use get_tree() without an engine error
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var gm := StandardMaterial3D.new()
	gm.resource_name = "glow"
	bm.material = gm
	mi.mesh = bm
	node.add_child(mi)
	var p := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for clip in ["idle", "walk", "attack", "hit", "die"]:
		var a := Animation.new()
		a.length = 0.4
		lib.add_animation(clip, a)
	p.add_animation_library("", lib)
	node.add_child(p)
	CreatureAnim._wrap(node, glow)

	SmokeTest._check("creature anim: glow material replaced",
		mi.get_surface_override_material(0) == glow)
	SmokeTest._check("creature anim: idle/walk loop at load",
		p.get_animation("idle").loop_mode == Animation.LOOP_LINEAR
		and p.get_animation("walk").loop_mode == Animation.LOOP_LINEAR)
	CreatureAnim.move(node, 3.0)
	SmokeTest._check("creature anim: move fast -> walk at 3x",
		p.current_animation == "walk" and is_equal_approx(p.speed_scale, 3.0),
		"(%s x%.1f)" % [p.current_animation, p.speed_scale])
	node.set_meta("_anim_scale", 2.0)  # Skitter-like: walk authored at 1 m/s, model at u=2
	CreatureAnim.move(node, 4.0)
	SmokeTest._check("creature anim: speed_scale divides by model scale",
		is_equal_approx(p.speed_scale, 2.0), "(x%.1f)" % p.speed_scale)
	node.set_meta("_anim_scale", 1.0)
	CreatureAnim.flap(node)
	SmokeTest._check("creature anim: flap plays walk at 1x",
		p.current_animation == "walk" and is_equal_approx(p.speed_scale, 1.0))
	CreatureAnim.move(node, 0.0)
	SmokeTest._check("creature anim: move stopped -> idle", p.current_animation == "idle")
	CreatureAnim.attack(node)
	SmokeTest._check("creature anim: attack plays", p.current_animation == "attack")
	CreatureAnim.move(node, 3.0)
	SmokeTest._check("creature anim: move does not stomp attack", p.current_animation == "attack")
	CreatureAnim.hit(node)
	SmokeTest._check("creature anim: hit plays", p.current_animation == "hit")

	var fired := [false]
	CreatureAnim.die(node, func() -> void: fired[0] = true)
	SmokeTest._check("creature anim: die defers the callback", not fired[0])
	p.animation_finished.emit("die")
	SmokeTest._check("creature anim: die fires after the clip", fired[0])

	var fired2 := [false]
	var bare := Node3D.new()  # no player: procedural path calls back at once
	CreatureAnim.die(bare, func() -> void: fired2[0] = true)
	SmokeTest._check("creature anim: die without clip calls at once", fired2[0])
	node.queue_free()
	bare.queue_free()


## Raider death removes targeting at once; the node is freed (immediately with the
## procedural fallback, after the die clip with a model).
static func _raider_kill_path(g) -> void:
	var nests: SporeNests = g.hazards.nests
	var alive_nests: Array = nests.nests.filter(func(n): return n.alive)
	if alive_nests.is_empty():
		SmokeTest._check("creature anim: raider kill path", false, "(no live nest)")
		return
	nests.raiders.spawn(alive_nests[0], RaiderDefs.named("Skitter"), false)
	var r: Dictionary = nests.raiders.list.back()
	var node: Node3D = r.node
	var target: Dictionary = r.target
	var before: int = nests.raiders.list.size()
	nests.raiders.kill(r)
	# queue_free() applies at frame end; queued-for-deletion is the observable proof.
	# With a model, the death clip plays first (freed when it finishes); procedural
	# frees immediately.
	var modeled := _find_player(node) != null
	if modeled:
		var kp := _find_player(node)
		SmokeTest._check("creature anim: kill plays death clip",
			kp != null and kp.current_animation == "die")
	else:
		SmokeTest._check("creature anim: kill frees node (procedural)", node.is_queued_for_deletion())
	SmokeTest._check("creature anim: kill drops targeting",
		not g.surface.targets.has(target) and not r.alive)
	SmokeTest._check("creature anim: kill erases from list", nests.raiders.list.size() == before - 1)
