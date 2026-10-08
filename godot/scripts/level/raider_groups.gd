class_name RaiderGroups
## Mixed raids from pressure GROUP_PRESSURE (§4.2). A group is 50% front line, 35% ranged
## and 15% support, chosen without the global RNG so a smoke can pin the shares.
## Front line is Skitter, Brute, Ravager, Behemoth. Burrowers stay out of that pool.
## Spotters are not in groups. The group mills for GROUP_GATHER, then every member moves
## at the slowest living member's speed.


static func size_for(p: float) -> int:
	return clampi(roundi(lerpf(float(Config.GROUP_MIN), float(Config.GROUP_MAX), clampf(p, 0.0, 1.0))), Config.GROUP_MIN, Config.GROUP_MAX)


## `salt` shifts which rows fill the shares. 0 is the even spread (10 / 7 / 3 at n = 20).
static func compose(n: int, p: float, salt := 0) -> Array:
	var pools := { "front": _pool(p, "front"), "ranged": _pool(p, "ranged"), "support": _pool(p, "support") }
	var out: Array = []
	var denom := float(maxi(n, 1) + 1)
	for i in maxi(n, 0):
		var roll := fposmod(float(i + 1) / denom + float(salt) * 0.173, 1.0)
		var role := "support"
		if roll < Config.GROUP_FRONT:
			role = "front"
		elif roll < Config.GROUP_FRONT + Config.GROUP_RANGED:
			role = "ranged"
		out.append(_from(pools, role, fposmod(float(i) * 0.37 + float(salt) * 0.11, 1.0)))
	return out


static func spawn(host: Raiders, nest: Dictionary, tiers: Array, mission := "") -> int:
	if tiers.is_empty():
		return -1
	var gid := host.next_group
	host.next_group += 1
	var n := 0
	for row in tiers:
		if host.list.size() >= Config.RAIDER_MAX_TOTAL:
			break
		host.spawn(nest, row as Dictionary, false)
		var r := host.list.back() as Dictionary
		r["group"] = gid
		r["gather"] = Config.GROUP_GATHER
		if mission != "":
			r["mission"] = mission
		n += 1
	return gid if n > 0 else -1


static func speed(host: Raiders, r: Dictionary) -> float:
	var own: float = float((r.tier as Dictionary).speed)
	var gid := int(r.get("group", -1))
	if gid < 0:
		return own
	var slow := own
	for o in host.list:
		if not o.alive or int(o.get("group", -1)) != gid:
			continue
		slow = minf(slow, float((o.tier as Dictionary).speed))
	return slow


static func _pool(p: float, role: String) -> Array:
	var rows: Array = []
	for row in RaiderDefs.unlocked(p):
		var d: Dictionary = row
		var special := str(d.get("special", ""))
		if special == "burrow" or special == "spotter":
			continue
		if str(d.role) == role:
			rows.append(d)
	return rows


static func _from(pools: Dictionary, role: String, roll: float) -> Dictionary:
	var rows: Array = pools[role] as Array
	if rows.is_empty():
		rows = pools["front"] as Array
	if rows.is_empty():
		return RaiderDefs.named("Skitter")
	var total := 0
	for i in rows.size():
		total += 1 << i
	var ticket := mini(total - 1, int(floor(clampf(roll, 0.0, 0.9999) * float(total))))
	var acc := 0
	for i in rows.size():
		acc += 1 << i
		if ticket < acc:
			return rows[i] as Dictionary
	return rows.back() as Dictionary
