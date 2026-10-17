class_name RangeTestCombat
## F97 phase D: fight-from-cover loop. At cover with a live contact the bot cycles
## HIDE (1.5-4 s) -> PEEK (sidestep to LOS, fire 1-3 s) -> HIDE; repositions after
## REPOSITION_PEEKS peeks, when flanked, or when the cover is exposed. BotBrain.next()
## stays a pure function of (state, facts).


static func _bot(t: RangeTest, session: RangeSession, stub: Node3D, pos: Vector3, name: String) -> ScavBot:
	var b := ScavBot.new()
	b.setup(session, t.bal, stub, name, 0, "rifleman")
	t.add_child(b)
	b.set_physics_process(false)
	b.global_position = pos
	return b


static func run(t: RangeTest) -> void:
	var o := Vector3(4000, 0, 4000)
	var session := RangeSession.new(54)
	session.noise.reset()
	var floor_body := t._wall(o + Vector3(0, -0.5, 0), Vector3(60, 1, 60), "concrete", 0.5)
	var wall := t._wall(o + Vector3(0, 0.6, 10), Vector3(8, 1.2, 0.5), "concrete", 0.5)
	var stub := RangeTestNoFire.Stub.new()
	var m1 := o + Vector3(0, 0, 12)
	var m2 := o + Vector3(0, 0, 16)
	stub.covers = [m1, m2]
	t.add_child(stub)
	var threat := o
	var b := _bot(t, session, stub, m2, "C")
	b.percept.contact.sight(threat)
	b.has_cover = true
	b.cover_pos = m2
	for i in 3:
		await t.get_tree().physics_frame
	var space := b.get_world_3d().direct_space_state
	var cb := b.combat

	# hide -> peek: first tick (sub_dur 0) peeks immediately
	BotCombat.tick(b, 0.1)
	t.check("combat: hide expires into peek", cb.sub == BotCombat.PEEK)
	t.check("combat: peek burst lasts 1-3 s", cb.sub_dur >= 1.0 and cb.sub_dur <= 3.0, "%.2f" % cb.sub_dur)
	var aim := threat + Vector3(0, BotCover.THREAT_EYE, 0)
	t.check("combat: peek point has LOS to the contact",
		BotPerception.los(space, cb.peek_pos + Vector3(0, BotCover.STAND_EYE, 0), [aim]), str(cb.peek_pos - o))
	t.check("combat: peek is a sidestep from the cover",
		absf((cb.peek_pos - m2).length()) > 0.5 and absf((cb.peek_pos - m2).length()) < 3.0, "%.2f" % (cb.peek_pos - m2).length())
	# peek -> hide
	BotCombat.tick(b, cb.sub_dur + 0.1)
	t.check("combat: peek expires into hide", cb.sub == BotCombat.HIDE)
	t.check("combat: hide lasts 1.5-4 s", cb.sub_dur >= 1.5 and cb.sub_dur <= 4.0, "%.2f" % cb.sub_dur)
	t.check("combat: peek counted", cb.peeks == 1)
	# hide -> peek again: a new sidestep (not the identical spot forever)
	var p1 := cb.peek_pos
	BotCombat.tick(b, cb.sub_dur + 0.1)
	t.check("combat: second peek re-sidesteps", cb.sub == BotCombat.PEEK and cb.peek_pos.distance_to(p1) > 0.01,
		"%s vs %s" % [str(cb.peek_pos - o), str(p1 - o)])

	# reposition after REPOSITION_PEEKS peeks
	cb.peeks = BotTacticsDefs.REPOSITION_PEEKS
	cb.sub = BotCombat.HIDE
	cb.sub_t = 0.0
	BotCombat.tick(b, 0.1)
	t.check("combat: repositions after %d peeks" % BotTacticsDefs.REPOSITION_PEEKS, cb.sub == BotCombat.REPOSITION)
	t.check("combat: reposition resets the peek count", cb.peeks == 0)

	# reposition when flanked: claim the cover against a threat 90 deg away
	cb.sub = BotCombat.HIDE
	cb.sub_t = 0.0
	b.cover_pos = m2
	b.global_position = m2
	BotCover.claim(session, b, m2, m2 + Vector3(16, BotCover.THREAT_EYE, 0))
	BotCombat.tick(b, 0.1)
	t.check("combat: repositions when flanked", cb.sub == BotCombat.REPOSITION)
	BotCover.release(session, b)

	# reposition when the cover is exposed (no longer hidden from the contact)
	cb.sub = BotCombat.HIDE
	cb.sub_t = 0.0
	var m3 := o + Vector3(0, 0, 4)  # between wall and threat: visible
	b.cover_pos = m3
	b.global_position = m3
	BotCombat.tick(b, 0.1)
	t.check("combat: repositions when the cover is exposed", cb.sub == BotCombat.REPOSITION)

	# BotBrain.next() is still pure: same facts -> same transition, no hidden state
	var f := {"aware": true, "seeing": false, "since_seen": 99.0, "has_last": true, "flank_eager": false,
		"ally_flank": false, "reloading": false, "outgunned": false, "hurt": false, "hp": 1.0, "cover": true}
	t.check("combat: BotBrain.next() is pure", BotBrain.next(BotBrain.ENGAGE, f) == BotBrain.next(BotBrain.ENGAGE, f)
		and BotBrain.next(BotBrain.ENGAGE, f) == BotBrain.SEARCH)

	b.queue_free()
	stub.queue_free()
	wall.queue_free()
	floor_body.queue_free()
