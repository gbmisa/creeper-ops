class_name SmokePlaytestSmall
## Playtest-small fixes: --cheat-guns unlocks every Operative weapon, and NPC
## animations freeze while the game is paused. Called from SmokeTest.run.


static func run(g) -> void:
	_cheat_guns(g)
	_pause_freeze(g)


static func _cheat_guns(g) -> void:
	OperativeUpgrades.cheat_guns = true
	var ok := true
	for id in ["railgun", "plasma"]:
		ok = ok and OperativeUpgrades.unlocked(id)
	SmokeTest._check("playtest-small: cheat-guns unlocks all weapons", ok)
	OperativeUpgrades.cheat_guns = false
	# With the cheat off, unlocked() must follow the real upgrade levels again,
	# whatever earlier smoke files left behind.
	ok = true
	for id in ["railgun", "plasma"]:
		ok = ok and OperativeUpgrades.unlocked(id) == (OperativeUpgrades.level("unlock_" + id) > 0)
	SmokeTest._check("playtest-small: cheat off restores normal gating", ok)


static func _pause_freeze(g) -> void:
	# Hand-built animated node (same wrap path make() uses, no .glb needed).
	var node := Node3D.new()
	g.add_child(node)
	var p := AnimationPlayer.new()
	var lib := AnimationLibrary.new()
	for clip in ["idle", "walk"]:
		var a := Animation.new()
		a.length = 0.4
		lib.add_animation(clip, a)
	p.add_animation_library("", lib)
	node.add_child(p)
	CreatureAnim._wrap(node, null)
	CreatureAnim.move(node, 3.0)
	SmokeTest._check("playtest-small: sanity, walk playing",
		p.current_animation == "walk" and p.is_playing())

	CreatureAnim.set_all_paused(g.get_tree(), true)
	SmokeTest._check("playtest-small: paused freezes clip playback",
		is_equal_approx(p.speed_scale, 0.0), "(x%.1f)" % p.speed_scale)

	CreatureAnim.set_all_paused(g.get_tree(), false)
	SmokeTest._check("playtest-small: unpause resumes clip playback",
		is_equal_approx(p.speed_scale, 1.0), "(x%.1f)" % p.speed_scale)
	node.queue_free()
