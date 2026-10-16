class_name RangeTestSquad
## F97 phase C: squad planner. Squads build from ally/leader links + spawn proximity; roles respect
## the caps (at most half push, at most 1 flank); marksman/warlord always hold, breacher advances,
## runner flanks, rifleman by range band; flank arcs go >= 60 deg off the direct line on the side
## away from the advancer; movers take different covers; spacing (4 m) and the 12 deg line-of-fire
## rule reject picks.


static func _bot(t: RangeTest, session: RangeSession, stub: Node3D, pos: Vector3, name: String, kind := "rifleman") -> ScavBot:
	var b := ScavBot.new()
	b.setup(session, t.bal, stub, name, 0, kind)
	t.add_child(b)
	b.set_physics_process(false)
	b.global_position = pos
	return b


static func _roles(sq: BotSquad) -> Dictionary:
	var n := {"hold": 0, "advance": 0, "flank": 0}
	for m in sq.members:
		n[sq.roles[m]] += 1
	return n


static func run(t: RangeTest) -> void:
	var o := Vector3(4000, 0, 4000)
	var session := RangeSession.new(53)
	session.noise.reset()
	var stub := RangeTestNoFire.Stub.new()
	t.add_child(stub)
	_planner(t, session, stub, o)
	await _integration(t)
	stub.queue_free()


static func _planner(t: RangeTest, session: RangeSession, stub: Node3D, o: Vector3) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var contact := o + Vector3(0, 0, 50)

	# 4 bots: ally links + proximity -> one squad
	var r1 := _bot(t, session, stub, o + Vector3(-5, 0, 0), "R1")
	var r2 := _bot(t, session, stub, o + Vector3(5, 0, 0), "R2")
	var p := _bot(t, session, stub, o + Vector3(0, 0, -5), "P", "pistol")
	var s := _bot(t, session, stub, o + Vector3(0, 0, 5), "S", "shotgunner")
	r1.ally = r2
	r2.ally = r1
	var squads := BotSquad.build([r1, r2, p, s])
	t.check("squad: ally-linked bots form one squad", squads.size() == 1 and (squads[0] as BotSquad).members.size() == 4)
	var iso := _bot(t, session, stub, o + Vector3(200, 0, 200), "Iso")
	t.check("squad: an isolated bot is its own squad", BotSquad.build([r1, r2, p, s, iso]).size() == 2)

	var sq: BotSquad = squads[0]
	sq.plan(contact, rng)
	var n := _roles(sq)
	# prefs: r1/r2 advance (50 m > 40), p flank, s advance -> push 4 > cap 2 -> demote the riflemen
	t.check("squad: at most half the squad pushes", n["advance"] + n["flank"] <= 2, str(n))
	t.check("squad: at most one flanks", n["flank"] <= 1, str(n))
	t.check("squad: the runner takes the flank", sq.roles[p] == BotSquad.ROLE_FLANK)
	t.check("squad: the breacher advances", sq.roles[s] == BotSquad.ROLE_ADVANCE)
	t.check("squad: demoted riflemen hold", sq.roles[r1] == BotSquad.ROLE_HOLD and sq.roles[r2] == BotSquad.ROLE_HOLD)

	# marksman and warlord never push, even at range
	var mm := _bot(t, session, stub, o + Vector3(0, 0, 0), "MM", "marksman")
	var bo := _bot(t, session, stub, o + Vector3(10, 0, 0), "BO", "boss")
	var sq2: BotSquad = BotSquad.build([mm, bo])[0]
	sq2.plan(o + Vector3(0, 0, 60), rng)
	t.check("squad: the marksman always holds", sq2.roles[mm] == BotSquad.ROLE_HOLD)
	t.check("squad: the warlord holds", sq2.roles[bo] == BotSquad.ROLE_HOLD)

	# rifleman by range band
	var r := _bot(t, session, stub, o + Vector3(0, 0, 0), "R")
	var sq3: BotSquad = BotSquad.build([r])[0]
	sq3.plan(o + Vector3(0, 0, 50), rng)
	t.check("squad: rifleman advances when the contact is far", sq3.roles[r] == BotSquad.ROLE_ADVANCE)
	sq3.plan(o + Vector3(0, 0, 20), rng)
	t.check("squad: rifleman holds inside the band", sq3.roles[r] == BotSquad.ROLE_HOLD)

	# flank geometry: flanker arcs >= 60 deg off the direct line, away from the advancer
	var f := _bot(t, session, stub, o + Vector3(-5, 0, 0), "F", "pistol")
	var ad := _bot(t, session, stub, o + Vector3(5, 0, 0), "AD", "shotgunner")
	var r3 := _bot(t, session, stub, o + Vector3(0, 0, -10), "R3")
	var sq4: BotSquad = BotSquad.build([f, ad, r3])[0]
	sq4.plan(contact, rng)
	t.check("squad: flanker assigned", sq4.roles[f] == BotSquad.ROLE_FLANK and sq4.roles[ad] == BotSquad.ROLE_ADVANCE)
	t.check("squad: flanker takes the side away from the advancer", sq4.flank_side[f] == 1.0, str(sq4.flank_side.get(f)))
	var fp: Vector3 = BotSquad.flank_point(sq4, f)
	var axis := Vector2(0, 1)  # squad center (o + (0,0,-3.3)) -> contact (o + (0,0,50))
	var arc := rad_to_deg(axis.angle_to(Vector2(fp.x - o.x, fp.z - o.z - 50.0).normalized()))
	t.check("squad: flank arc is >= 60 deg off the direct line", arc >= 60.0, "%.1f" % arc)
	var adv_side := signf(axis.x * 3.3 - axis.y * 5.0)
	var fp_side := signf(axis.x * (fp.z - o.z + 3.3) - axis.y * (fp.x - o.x))
	t.check("squad: flank point is opposite the advancer", fp_side == -adv_side, str(fp - o))

	# re-plan triggers
	t.check("squad: no re-plan when nothing changed", not sq4.needs_replan(contact))
	sq4.plan_age = 999.0
	t.check("squad: re-plan on the timer", sq4.needs_replan(contact))
	sq4.plan(contact, rng)
	t.check("squad: re-plan when the contact moves", sq4.needs_replan(contact + Vector3(15, 0, 0)))
	r3.body.dead = true
	t.check("squad: re-plan when a member dies", sq4.needs_replan(contact))

	for b in [r1, r2, p, s, iso, mm, bo, r, f, ad, r3]:
		(b as ScavBot).queue_free()


static func _integration(t: RangeTest) -> void:
	var o := Vector3(4000, 0, 4000)
	var session := RangeSession.new(52)
	session.noise.reset()
	var floor_body := t._wall(o + Vector3(0, -0.5, 0), Vector3(60, 1, 60), "concrete", 0.5)
	var wall := t._wall(o + Vector3(0, 0.6, 10), Vector3(8, 1.2, 0.5), "concrete", 0.5)
	var stub := RangeTestNoFire.Stub.new()
	var m1 := o + Vector3(0, 0, 12)
	var m2 := o + Vector3(0, 0, 16)
	stub.covers = [m1, m2]
	t.add_child(stub)
	var threat := o
	var bots: Array = []
	for i in 4:
		var b := _bot(t, session, stub, o + [Vector3(-45, 0, 20), Vector3(-45, 0, 24), Vector3(-43, 0, 22), Vector3(-47, 0, 22)][i], "S%d" % i)
		b.percept.contact.sight(threat)
		bots.append(b)
	for i in 3:
		await t.get_tree().physics_frame

	# spacing and line-of-fire rules, unit level (in-tree so positions read back)
	var sa := _bot(t, session, stub, o + Vector3(0, 0, 0), "SA")
	var sb := _bot(t, session, stub, o + Vector3(30, 0, 0), "SB")
	sa.percept.contact.sight(o + Vector3(0, 0, 50))
	sb.percept.contact.sight(o + Vector3(0, 0, 50))
	var sqab: BotSquad = BotSquad.build([sa, sb])[0]
	t.check("squad: spacing rejects a marker near an ally", BotCover._squad_blocks(sb, o + Vector3(2, 0, 0), sqab))
	t.check("squad: spacing allows a distant marker", not BotCover._squad_blocks(sb, o + Vector3(15, 0, 10), sqab))
	# sa and sc in one squad (22 m apart); marker collinear with sc seen from the contact
	var sc := _bot(t, session, stub, o + Vector3(10, 0, 20), "SC")
	sc.percept.contact.sight(o + Vector3(0, 0, 50))
	var sqac: BotSquad = BotSquad.build([sa, sc])[0]
	t.check("squad: line-of-fire rejects a marker behind an ally", BotCover._squad_blocks(sa, o + Vector3(12, 0, 14), sqac))

	# two advancers take different covers: scored pick + reservation
	var sq: BotSquad = BotSquad.build(bots)[0]
	sq.contact_pos = threat
	sq.roles[bots[0]] = BotSquad.ROLE_ADVANCE
	sq.roles[bots[1]] = BotSquad.ROLE_ADVANCE
	sq.roles[bots[2]] = BotSquad.ROLE_HOLD
	sq.roles[bots[3]] = BotSquad.ROLE_HOLD
	for m in bots:
		(m as ScavBot).squad = sq
	var nb: Vector3 = BotSquad.next_cover_toward(bots[1])
	t.check("squad: advancer finds a cover toward the contact", nb != BotCover.NO_COVER, str(nb - o))
	BotCover.claim(session, bots[1], nb, threat)
	var na: Vector3 = BotSquad.next_cover_toward(bots[0])
	t.check("squad: two advancers take different covers", na != BotCover.NO_COVER and na.distance_to(nb) > 0.01,
		"%s vs %s" % [str(na - o), str(nb - o)])

	for b in [sa, sb, sc]:
		(b as ScavBot).queue_free()
	for b in bots:
		(b as ScavBot).queue_free()
	stub.queue_free()
	wall.queue_free()
	floor_body.queue_free()
