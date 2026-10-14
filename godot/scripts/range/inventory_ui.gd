class_name InventoryUI
extends CanvasLayer
## Tab opens the inventory screen: mouse free, no shooting, movement still works. Applies the view's drag / drop /
## quick-move requests to the Inventory and keeps the ground grid (items within 2 m) in step with WorldItems.

var weapons: PlayerWeapons
var player: TacticalPlayer
var world: WorldItems
var view := InventoryView.new()
var is_open := false


func setup(w: PlayerWeapons, p: TacticalPlayer, wi: WorldItems) -> void:
	weapons = w
	player = p
	world = wi
	layer = 8
	visible = false
	view.inv = w.inv
	view.drop_requested.connect(_on_drop)
	view.quick_requested.connect(quick_move)
	add_child(view)


func _process(_dt: float) -> void:
	if player.input.act("inventory") and (is_open or player.enabled):
		if is_open:
			close()
		else:
			open()


func open() -> void:
	is_open = true
	visible = true
	weapons.ui_open = true
	refresh_ground()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	view.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	weapons.ui_open = false
	view.drag = {}
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Ground grid = the world items within reach; existing cells are kept, new ones take the first free spot.
func refresh_ground() -> void:
	var inv := weapons.inv
	var near := world.nearby(player.eye_pos())
	for it in inv.ground.duplicate():
		if not near.has(it):
			inv.remove(it)
	for it in near:
		if it["loc"] != "ground":
			it["loc"] = ""
			for rot in [it["rot"], 1 - int(it["rot"])]:
				if _put_ground(inv, it, rot):
					break


func _put_ground(inv: Inventory, it: Dictionary, rot: int) -> bool:
	var gs := inv.grid_size("ground")
	for y in gs.y:
		for x in gs.x:
			if inv.fits("ground", it, x, y, rot):
				return inv.place(it, "ground", x, y, rot)
	return false


func _on_drop(it: Dictionary, target: Dictionary, origin: Dictionary) -> void:
	var inv := weapons.inv
	if target.is_empty():
		_to_world(it)
	elif inv.is_slot(target["loc"]):
		_into_slot(it, target, origin)
	else:
		_into_grid(it, target)
	_settle()


func _into_grid(it: Dictionary, t: Dictionary) -> void:
	var inv := weapons.inv
	if ItemDefs.def_of(it)["kind"] == "ammo":  # drop onto a stack of the same ammo to merge
		for o in inv.grid_items(t["loc"]):
			if o["uid"] != it["uid"] and o["id"] == it["id"] and Rect2i(Vector2i(o["x"], o["y"]), inv.size_of(o)).intersects(Rect2i(Vector2i(t["x"], t["y"]), inv.size_of(it, t["rot"]))):
				var was_world: bool = it.has("world")
				inv.merge_stack(it, o)
				if it["count"] <= 0 and was_world:
					world.release(it)
				return
	var from_ground: bool = it["loc"] == "ground"
	if inv.move(it, t):
		_snd(it, "pick" if from_ground and t["loc"] != "ground" else "move")
		if t["loc"] != "ground" and it.has("world"):
			world.release(it)


func _into_slot(it: Dictionary, t: Dictionary, origin: Dictionary) -> void:
	var inv := weapons.inv
	var slot: String = t["loc"]
	if not inv.accepts_slot(slot, it):
		return
	_snd(it, "move")
	var occ = inv.equipped(slot)
	if occ == null:
		if inv.move(it, t) and it.has("world"):
			world.release(it)
		return
	inv.remove(it)
	inv.remove(occ)
	inv.place(it, slot, 0, 0, 0)
	if it.has("world"):
		world.release(it)
	if origin["loc"] != "ground" and inv.move(occ, origin):
		return
	if not inv.add(occ):
		world.drop_front(occ)


func _to_world(it: Dictionary) -> void:
	if it["loc"] == "ground":
		return
	_snd(it, "drop")
	weapons.inv.remove(it)
	world.drop_front(it)


## Ctrl+click: ground -> first fit in the inventory; carried -> first fit elsewhere, else onto the ground.
func quick_move(it: Dictionary) -> void:
	var inv := weapons.inv
	if it["loc"] == "ground":
		if world.take(it, inv):
			_snd(it, "pick")
		else:
			weapons.message.emit("No room for %s" % ItemDefs.label(it))
	else:
		var from: String = it["loc"]
		var to := inv.first_fit(it, from)
		if to.is_empty() or not inv.move(it, to):
			_to_world(it)
		else:
			_snd(it, "move")
	_settle()


func _snd(it: Dictionary, ev: String) -> void:
	RangeAudio.event({"kind": "inventory", "item": ItemDefs.def_of(it)["kind"], "ev": ev, "local": true})


## Items put on the ground grid become physical; then everything is re-synced.
func _settle() -> void:
	var inv := weapons.inv
	for it in inv.ground.duplicate():
		if not it.has("world"):
			inv.remove(it)
			world.drop_front(it)
	weapons.sync()
	refresh_ground()
	view.queue_redraw()
