class_name QuickUse
extends Node
## Quick-use items (meds) on keys 4.. (`t_slot_4` + n, ItemDefs.QUICK order) or a click on their QuickBar card.
## Using one keeps the hands busy for its `use` seconds (no firing or aiming), then takes the item out of the
## inventory and applies it. Death cancels; an item dropped mid-use is simply not applied.
## A med with a "res" HP pool (IFAK) is reusable: each use spends the HP it restores; it is removed at 0.

var weapons: PlayerWeapons
var player: TacticalPlayer
var using := ""
var left := 0.0


func setup(w: PlayerWeapons, p: TacticalPlayer) -> void:
	weapons = w
	player = p


func count(id: String) -> int:
	var n := 0
	for it in weapons.inv.all_items():
		if it["id"] == id:
			n += 1
	return n


func _find(id: String) -> Dictionary:
	for it in weapons.inv.all_items():
		if it["id"] == id:
			return it
	return {}


## Starts using `id`. Returns "" or why it refused (shown to the player).
func start(id: String) -> String:
	if using != "":
		return "Hands busy"
	if player.body.dead or not player.enabled:
		return "Can't now"
	if count(id) == 0:
		return "No %s" % ItemDefs.of(id)["name"]
	var d := ItemDefs.of(id)
	if not d.has("heal") and d.get("stop_bleed", false) and player.body.bleeds.is_empty():
		return "Not bleeding"
	if d.has("heal") and player.body.full_health() and player.body.bleeds.is_empty():
		return "Full health"
	if weapons.gun != null and weapons.gun.busy_kind == "reload":
		return "Reloading"
	using = id
	left = float(d["use"])
	weapons.hands_busy = true
	RangeAudio.event({"kind": "inventory", "item": "med", "ev": "move", "local": true})
	return ""


func cancel() -> void:
	using = ""
	left = 0.0
	weapons.hands_busy = false


## Seconds of the current use done, 0..1 (0 when idle).
func progress() -> float:
	if using == "":
		return 0.0
	return 1.0 - left / float(ItemDefs.of(using)["use"])


func _process(dt: float) -> void:
	if weapons == null:
		return
	if using != "":
		if player.body.dead:
			cancel()
			return
		left -= dt
		if left <= 0.0:
			_finish()
	if not player.enabled:
		return
	for n in ItemDefs.QUICK.size():
		if player.input.frame.act("t_slot_%d" % (n + 4)):
			request(ItemDefs.QUICK[n])


## Key or card click: start, or say why not.
func request(id: String) -> void:
	var why := start(id)
	if why != "":
		weapons.message.emit(why)


func _finish() -> void:
	var id := using
	cancel()
	var it := _find(id)
	if it.is_empty():
		return
	var d := ItemDefs.of(id)
	var msg := "Used %s" % d["name"]
	if it.has("res"):
		it["res"] = float(it["res"]) - player.body.heal(float(d["heal"]), float(it["res"]))
		if float(it["res"]) < 1.0:
			weapons.inv.remove(it)
		else:
			msg += " (%d HP left)" % int(it["res"])
	else:
		weapons.inv.remove(it)
		if d.has("heal"):
			player.body.heal(float(d["heal"]))
		elif d.get("stop_bleed", false):
			player.body.stop_bleeds()
	RangeAudio.event({"kind": "inventory", "item": "med", "ev": "drop", "local": true})
	weapons.message.emit(msg)
