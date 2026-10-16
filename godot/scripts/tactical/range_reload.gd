class_name RangeReload
extends RefCounted
## F69: reloads on infinite-ammo maps (RangeMaps.INFINITE_AMMO). The incoming mag/shell is brand new and full, of the
## gun's chosen ammo type; the inventory is never read or written and the old mag is thrown away (never kept in
## Gun.spares). Gun still plays the whole reload (timings, chamber, animation events). Skirmish uses InvReload.


## "ok" or "no" (the gun can't reload now). Never "none": the range does not run dry.
static func begin(gi: Dictionary, fast: bool) -> String:
	var g: Gun = gi["gun"]
	if gi.has("staged"):  # second R during a reload: Gun decides (fast-reload upgrade)
		return "ok" if g.reload(fast) else "no"
	var action: String = g.def["action"]
	if g.busy() or g.needs_cycle or (action == "enbloc" and g.mag.count() > 0) or (action == "tube" and g.mag.is_full()):
		return "no"
	var fresh: Magazine
	if action == "tube":
		fresh = Magazine.new(1)  # one shell per press, of the type already in the tube
		fresh.push(g.mag.top() if g.mag.count() > 0 else g.ammo_pick)
	else:
		fresh = Magazine.new(maxi(int(WeaponDefs.of(g.def["id"]).get("mag", 0)), int(g.stat("mag"))))
		fresh.fill(g.ammo_pick)
	g.spares.clear()
	g.spares.append(fresh)
	if not g.reload(fast):
		g.spares.clear()
		return "no"
	gi["staged"] = {"free": true}
	return "ok"


## Reload done: whatever the gun still holds in spares (the discarded old mag) is dropped.
static func finish(gi: Dictionary) -> void:
	(gi["gun"] as Gun).spares.clear()
	gi.erase("staged")


static func cancel(gi: Dictionary) -> void:
	if not gi.has("staged"):
		return
	var g: Gun = gi["gun"]
	gi.erase("staged")
	g.busy_t = 0.0
	g.busy_kind = ""
	g.spares.clear()
