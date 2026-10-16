class_name InvReload
extends RefCounted
## Connects a Gun's reload to the inventory. begin() pulls the fullest compatible mag (rig, pockets, then backpack)
## into gun.spares and remembers where it came from; finish() puts the old mag back there (or first fit);
## cancel() undoes a half-done reload. Gun itself is unchanged. Shotgun tubes consume one loose round per reload.

var inv: Inventory
## Range map: reloads never run dry. The incoming mag/round is made fresh and full, the inventory is not touched.
var infinite := false


func _init(i: Inventory) -> void:
	inv = i


static func mag_from_item(it: Dictionary, min_cap: int = 0) -> Magazine:
	var m := Magazine.new(maxi(maxi(ItemDefs.def_of(it)["cap"], min_cap), int(it["rounds"])))
	for i in int(it["rounds"]):
		m.push(it["ammo"])
	return m


func item_from_mag(gun_id: String, m: Magazine, fallback_ammo: String) -> Dictionary:
	var id := "clip_garand" if gun_id == "garand" else "mag_" + gun_id
	return inv.make(id, {"rounds": m.count(), "ammo": m.top() if m.count() > 0 else fallback_ammo})


## "ok", "none" (no magazine / round found) or "no" (the gun can't reload now).
func begin(gi: Dictionary, fast: bool) -> String:
	var g: Gun = gi["gun"]
	if gi.has("staged"):
		return "ok" if g.reload(fast) else "no"
	var action: String = g.def["action"]
	if action == "tube":
		return _begin_tube(gi, g, fast)
	if g.busy() or g.needs_cycle or (action == "enbloc" and g.mag.count() > 0):
		return "no"
	if infinite:
		return _begin_free(gi, g, fast)
	var mags := inv.find_mags(g.def["id"])
	if mags.is_empty():
		return "none"
	var m: Dictionary = mags[0]
	var from := {"loc": m["loc"], "x": m["x"], "y": m["y"], "rot": m["rot"]}
	inv.remove(m)
	g.spares.clear()
	g.spares.append(mag_from_item(m, int(g.stat("mag"))))
	if not g.reload(fast):
		g.spares.clear()
		inv.place(m, from["loc"], from["x"], from["y"], from["rot"])
		return "no"
	gi["staged"] = {"from": from}
	return "ok"


## Infinite ammo: a full mag of the gun's loaded grade; nothing leaves or enters the inventory.
func _begin_free(gi: Dictionary, g: Gun, fast: bool) -> String:
	var it := inv.make("clip_garand" if g.def["id"] == "garand" else "mag_" + g.def["id"])
	it["rounds"] = maxi(int(ItemDefs.def_of(it)["cap"]), int(g.stat("mag")))
	it["ammo"] = g.ammo_pick
	g.spares.clear()
	g.spares.append(mag_from_item(it, int(g.stat("mag"))))
	if not g.reload(fast):
		g.spares.clear()
		return "no"
	gi["staged"] = {"free": true}
	return "ok"


func _begin_tube(gi: Dictionary, g: Gun, fast: bool) -> String:
	if g.busy() or g.needs_cycle or g.mag.is_full():
		return "no"
	var round_id := g.ammo_pick if infinite else inv.take_round(g.def["cal"])
	if round_id == "":
		return "none"
	var pouch := Magazine.new(1)
	pouch.push(round_id)
	g.spares.clear()
	g.spares.append(pouch)
	if not g.reload(fast):
		g.spares.clear()
		if not infinite:
			inv.add(inv.make(round_id, {"count": 1}))
		return "no"
	gi["staged"] = {"round": round_id, "free": infinite}
	return "ok"


## Reload finished: the old mag (kept by Gun unless fast) goes back where the new one came from.
## Returns an item that did not fit anywhere (the caller drops it), or {}.
func finish(gi: Dictionary) -> Dictionary:
	var g: Gun = gi["gun"]
	var staged: Dictionary = gi.get("staged", {})
	gi.erase("staged")
	var leftover := {}
	if g.def["action"] == "detachable" and not g.spares.is_empty() and not staged.get("free", false):
		var old := item_from_mag(g.def["id"], g.spares[0], g.ammo_pick)
		var from: Dictionary = staged.get("from", {})
		if from.is_empty() or not inv.move(old, from):
			if not inv.add(old):
				leftover = old
	g.spares.clear()
	return leftover


## Abort (gun dropped or unequipped mid-reload): nothing is lost.
func cancel(gi: Dictionary) -> void:
	var g: Gun = gi["gun"]
	var staged: Dictionary = gi.get("staged", {})
	if staged.is_empty():
		return
	gi.erase("staged")
	g.busy_t = 0.0
	g.busy_kind = ""
	if staged.get("free", false):
		pass  # range ammo: nothing was taken
	elif staged.has("round"):
		inv.add(inv.make(staged["round"], {"count": 1}))
	elif not g.spares.is_empty():
		var back := item_from_mag(g.def["id"], g.spares[0], g.ammo_pick)
		var from: Dictionary = staged["from"]
		if not inv.move(back, from):
			inv.add(back)
	g.spares.clear()
