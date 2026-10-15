class_name RangeTestMp1
## MP-1 multiplayer-refactor checks for `--range-test`: per-player state isolation, bot targeting
## across two players, request-API rejection, deterministic recoil seeds, PlayerState round-trip.

static func run(t: RangeTest) -> void:
	_isolation(t)
	_targeting(t)
	_requests(t)
	_determinism(t)
	_state_round_trip(t)


## Two PlayerStates own independent inventories and recoil modes.
static func _isolation(t: RangeTest) -> void:
	var session := RangeSession.new(11)
	var a := session.add_player(1, true)
	var b := session.add_player(2, false)
	var it := a.inv.make("med_bandage")  # 1x1: pockets are 4x1
	a.inv.place(it, "pockets", 0, 0)
	t.check("mp1: inventories are per-player (item in A, B empty)", a.inv.all_items().has(it) and b.inv.all_items().is_empty())
	a.recoil_mode = true
	t.check("mp1: recoil_mode is per-player", a.recoil_mode and not b.recoil_mode)


## Bots target session.nearest_player: the nearer of two players wins, and it flips with distance.
static func _targeting(t: RangeTest) -> void:
	var session := RangeSession.new(12)
	var pa := session.add_player(1, true)
	var pb := session.add_player(2, false)
	var na := TacticalPlayer.new()
	var nb := TacticalPlayer.new()
	na.session = session
	nb.session = session
	pa.node = na
	pb.node = nb
	t.add_child(na)  # global_position needs the tree
	t.add_child(nb)
	na.set_process(false)
	na.set_physics_process(false)
	nb.set_process(false)
	nb.set_physics_process(false)
	na.position = Vector3(0, 0, 0)
	nb.position = Vector3(100, 0, 0)
	t.check("mp1: nearest_player picks the closer of two players", session.nearest_player(Vector3(10, 0, 0)) == pa)
	t.check("mp1: nearest_player flips when the other player is closer", session.nearest_player(Vector3(90, 0, 0)) == pb)
	na.queue_free()
	nb.queue_free()


## The request API rejects invalid mutations instead of applying them.
static func _requests(t: RangeTest) -> void:
	var inv := Inventory.new()
	inv.place(inv.make("pack_small"), "backpack")
	var a := inv.make("med_ifak")
	inv.place(a, "pack_g", 0, 0, 0)
	var b := inv.make("med_ifak")
	inv.place(b, "pack_g", 2, 0, 0)
	var r := inv.request_move(a, {"loc": "pack_g", "x": 2, "y": 0, "rot": 0})
	t.check("mp1: request_move onto an occupied cell is rejected", not r["ok"] and r["why"] != "")
	var c := inv.make("med_ifak")
	r = inv.request_place(c, "pack_g", 4, 0, 0)
	t.check("mp1: request_place out of bounds is rejected", not r["ok"] and r["why"] != "")
	r = inv.request_remove(inv.make("med_ifak"))
	t.check("mp1: request_remove of an item outside the inventory is rejected", not r["ok"] and r["why"] == "not in inventory")


## Same session seed -> same entity seed -> identical spray through the recoil shoot path.
static func _determinism(t: RangeTest) -> void:
	var s1 := RangeSession.new(99)
	var s2 := RangeSession.new(99)
	var sd := s1.next_seed()
	t.check("mp1: same session seed gives the same entity seed", sd == s2.next_seed())
	var def := WeaponDefs.of("ak47")
	var sprays := []
	for rep in 2:
		var rm := RecoilModel.new()
		rm.tarkov = true
		var rng := RandomNumberGenerator.new()
		rng.seed = sd
		var pts := []
		for i in 5:
			rm.shoot(def, rng)
			rm.update(60.0 / float(def["rpm"]), def["ergo"], def)
			pts.append(rm.offset)
		sprays.append(pts)
	t.check("mp1: same seed -> identical spray offsets", sprays[0] == sprays[1], str(sprays[0]))


## PlayerState serializes and restores peer, recoil mode, stats and the kit.
static func _state_round_trip(t: RangeTest) -> void:
	var session := RangeSession.new(13)
	var ps := session.add_player(7, false)
	ps.recoil_mode = true
	ps.stats = {"kills": 3, "shots": 10, "hits": 4}
	var ak := ps.inv.make("ak47")
	ps.inv.place(ak, "primary")
	var back := PlayerState.from_dict(ps.to_dict())
	var bg = back.inv.equipped("primary")
	t.check("mp1: PlayerState round-trips (peer, recoil mode, stats, kit)",
		back.peer_id == 7 and back.recoil_mode and back.stats == {"kills": 3, "shots": 10, "hits": 4} \
		and bg != null and bg["id"] == "ak47", str(back.to_dict().get("stats")))
