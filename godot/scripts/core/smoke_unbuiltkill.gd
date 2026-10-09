class_name SmokeUnbuiltKill
## Gregory's playtest: a placed-but-never-started Nullifier sat in creeper forever.
## Root cause: unbuilt reserve structures (weapons) lose build progress in creeper, but
## with zero delivered packets the loss was a no-op (minf(0, 0 + x) == 0) — immortal.
## Now an unbuilt weapon with no effective build progress dies on contact, like the
## briefing promises ("Creeper destroys anything it touches, built or not"). Partially
## built weapons still lose progress CW3-style; built weapons still soak HP.
## Called from SmokeTest.run.


static func run(g) -> void:
	var sm: StructureManager = g.structures
	var w: World = g.surface
	var x := 56
	var z := 56

	# 1. The reported bug: wet unbuilt nullifier, zero delivered packets -> destroyed.
	var n: Structure = sm.place("nullifier", x, z)
	_wet(w, n)
	StructureUpkeep.creeper_and_repair(sm, n, 1.0)
	SmokeTest._check("unbuiltkill: zero-progress nullifier dies in creeper", n.dead)
	_dry(w, n)

	# 2. Partially built weapon keeps CW3 progress loss (not destroyed outright).
	var c: Structure = sm.place("cannon", x + 3, z)
	c.delivered = 20
	_wet(w, c)
	StructureUpkeep.creeper_and_repair(sm, c, 1.0)
	SmokeTest._check("unbuiltkill: partial-progress cannon loses progress, survives",
		not c.dead and c.lost > 0.0, "(lost %.2f)" % c.lost)
	_dry(w, c)

	# 3. Built weapon still soaks creeper as HP damage.
	var b: Structure = sm.place("cannon", x + 6, z, true)
	var hp_before: float = b.hp
	_wet(w, b)
	StructureUpkeep.creeper_and_repair(sm, b, 1.0)
	SmokeTest._check("unbuiltkill: built cannon takes HP damage, survives",
		not b.dead and b.hp < hp_before, "(hp %.1f -> %.1f)" % [hp_before, b.hp])
	_dry(w, b)

	# 4. Unbuilt non-weapon structure still dies on contact (unchanged rule).
	var r: Structure = sm.place("relay", x + 9, z)
	_wet(w, r)
	StructureUpkeep.creeper_and_repair(sm, r, 1.0)
	SmokeTest._check("unbuiltkill: unbuilt relay dies on contact", r.dead)
	_dry(w, r)

	# 5. Dry unbuilt weapon is untouched.
	var d: Structure = sm.place("cannon", x + 12, z)
	StructureUpkeep.creeper_and_repair(sm, d, 1.0)
	SmokeTest._check("unbuiltkill: dry unbuilt cannon unaffected",
		not d.dead and d.lost == 0.0)

	# 6. Charging immunity needs a BUILT nullifier; charge never saves an unbuilt one.
	var nb: Structure = sm.place("nullifier", x + 15, z, true)
	nb.charge = 5.0
	_wet(w, nb)
	StructureUpkeep.creeper_and_repair(sm, nb, 1.0)
	SmokeTest._check("unbuiltkill: built charging nullifier immune",
		not nb.dead and is_equal_approx(nb.hp, nb.def.hp), "(hp %.1f)" % nb.hp)
	_dry(w, nb)
	var nu: Structure = sm.place("nullifier", x + 18, z)
	nu.charge = 5.0
	_wet(w, nu)
	StructureUpkeep.creeper_and_repair(sm, nu, 1.0)
	SmokeTest._check("unbuiltkill: unbuilt charging nullifier still dies", nu.dead)
	_dry(w, nu)

	for s in [c, b, d, nb]:
		if not s.dead:
			sm.remove(s)


static func _wet(w: World, s: Structure) -> void:
	for c in Placement.footprint_cells(s.type, s.x, s.z):
		w.creeper.set_depth(c.x, c.y, 1.0)


static func _dry(w: World, s: Structure) -> void:
	for c in Placement.footprint_cells(s.type, s.x, s.z):
		w.creeper.set_depth(c.x, c.y, 0.0)
