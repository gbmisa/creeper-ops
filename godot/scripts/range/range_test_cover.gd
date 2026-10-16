class_name RangeTestCover
## F97 phase B: scored cover + per-session reservation. Markers hidden from the contact are picked;
## visible ones are rejected; two bots never hold the same marker; a flanked claim is rejected;
## an exposed approach is penalised; re-picking frees the old claim.


static func _bot(t: RangeTest, session: RangeSession, stub: Node3D, pos: Vector3, name: String) -> ScavBot:
	var b := ScavBot.new()
	b.setup(session, t.bal, stub, name, 0, "rifleman")
	t.add_child(b)
	b.set_physics_process(false)
	b.global_position = pos
	return b


static func run(t: RangeTest) -> void:
	var o := Vector3(4000, 0, 4000)
	var session := RangeSession.new(51)
	session.noise.reset()
	var floor_body := t._wall(o + Vector3(0, -0.5, 0), Vector3(60, 1, 60), "concrete", 0.5)
	var wall := t._wall(o + Vector3(0, 0.6, 10), Vector3(8, 1.2, 0.5), "concrete", 0.5)
	var stub := RangeTestNoFire.Stub.new()
	var m1 := o + Vector3(0, 0, 12)
	var m2 := o + Vector3(0, 0, 16)
	var m3 := o + Vector3(0, 0, 4)  # between wall and threat: visible, never cover
	stub.covers = [m1, m2, m3]
	t.add_child(stub)
	var threat := o + Vector3(0, 0, 0)
	var a := _bot(t, session, stub, o + Vector3(-10, 0, 12), "A")
	var b := _bot(t, session, stub, o + Vector3(-10, 0, 14), "B")
	for b2 in [a, b]:
		b2.percept.contact.sight(threat)
	for i in 3:
		await t.get_tree().physics_frame
	var space := a.get_world_3d().direct_space_state

	# visible marker is rejected even though it is nearest the threat
	t.check("cover: visible marker is rejected", BotCover.score(a, m3, threat + Vector3(0, 1.4, 0), space) == -INF)
	# nearer marker loses to the farther one: its approach path is exposed to the threat
	var s1: float = BotCover.score(a, m1, threat + Vector3(0, 1.4, 0), space)
	var s2: float = BotCover.score(a, m2, threat + Vector3(0, 1.4, 0), space)
	t.check("cover: exposed approach penalised (%.1f < %.1f)" % [s1, s2], s1 < s2 and s2 > -INF)
	BotShooting.find_cover(a)
	t.check("cover: bot A takes the best marker", a.has_cover and a.cover_pos.distance_to(m2) < 0.01, str(a.cover_pos))
	t.check("cover: claim recorded on the session", session.cover_claims.has(m2))
	BotShooting.find_cover(b)
	t.check("cover: two bots never reserve the same cover", b.has_cover and b.cover_pos.distance_to(m2) > 0.01, str(b.cover_pos))
	t.check("cover: session holds two claims", session.cover_claims.size() == 2, str(session.cover_claims.size()))
	# re-picking frees the old claim
	BotCover.claim(session, a, m1, threat)
	t.check("cover: re-pick releases the old claim", BotCover.holder(session, m2) == null and BotCover.holder(session, m1) == a)
	# flanked claim: threat moved >60 deg around the marker -> rejected
	var t2 := o + Vector3(12, 1.4, 12)
	t.check("cover: flanked marker is rejected", BotCover.score(a, m1, t2, space) == -INF)
	BotCover.release(session, a)
	BotCover.release(session, b)
	t.check("cover: release frees all claims", session.cover_claims.is_empty())
	for b2 in [a, b]:
		b2.queue_free()
	stub.queue_free()
	wall.queue_free()
	floor_body.queue_free()
