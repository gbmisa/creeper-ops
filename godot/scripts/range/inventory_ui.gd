class_name InventoryUI
extends CanvasLayer
## Tab opens the inventory screen: mouse free, no shooting, movement still works. Applies the view's drag / drop /
## quick-move requests to the Inventory and keeps the ground grid (items within 2 m) in step with WorldItems.

var weapons: PlayerWeapons
var player: TacticalPlayer
var world: WorldItems
var view := InventoryView.new()
var is_open := false
var _zone_pop := PopupMenu.new()
var _zone_item := {}
var _health_panel: PanelContainer
var _health_lbl: Label


func setup(w: PlayerWeapons, p: TacticalPlayer, wi: WorldItems) -> void:
	weapons = w
	player = p
	world = wi
	layer = 8
	visible = false
	view.inv = w.inv
	view.drop_requested.connect(_on_drop)
	view.quick_requested.connect(quick_move)
	view.unfit_requested.connect(_on_unfit)
	view.use_requested.connect(_on_use)
	_zone_pop.id_pressed.connect(_on_zone_picked)
	add_child(_zone_pop)
	_health_panel = UiKit.panel(Color(0.04, 0.05, 0.07, 0.85))
	_health_panel.position = Vector2(1090, 60)
	_health_lbl = UiKit.mono("", 13)
	_health_panel.add_child(_health_lbl)
	_health_panel.visible = false
	add_child(_health_panel)
	add_child(view)


func _process(_dt: float) -> void:
	if player.input.act("inventory") and (is_open or player.enabled):
		if is_open:
			close()
		else:
			open()
	for i in 4:
		if player.input.act("med_quick_%d" % (i + 1)):
			_quick_med(i)
	if is_open:
		_health_lbl.text = _health_text()


func open() -> void:
	is_open = true
	visible = true
	weapons.ui_open = true
	refresh_ground()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_health_panel.visible = true
	_health_lbl.text = _health_text()
	view.queue_redraw()


func close() -> void:
	is_open = false
	visible = false
	weapons.ui_open = false
	view.drag = {}
	_health_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Right-click a med in the inventory: pick a body part when several qualify, else use at once.
func _on_use(it: Dictionary) -> void:
	var d := ItemDefs.def_of(it)
	var use: Dictionary = d.get("use", {})
	if use.is_empty():
		return
	var cands := StatusEffects.zone_candidates(player.body, use)
	if String(use.get("effect", "")) in ["stop_bleed", "fix_fracture", "surgery"] and cands.is_empty():
		weapons.message.emit("Nothing to treat with %s" % d["name"])
		return
	if cands.size() > 1:
		_zone_menu(it, cands)
	else:
		_use_med(it, String(cands[0]) if not cands.is_empty() else "")


func _use_med(it: Dictionary, zone: String) -> void:
	if not player.use_med(it, zone, weapons.inv):
		weapons.message.emit("Can't use that right now")


func _zone_menu(it: Dictionary, cands: Array) -> void:
	_zone_item = it
	_zone_pop.clear()
	for i in cands.size():
		var z := String(cands[i])
		_zone_pop.add_item("%s (%d/%d HP)" % [z.capitalize(), int(player.body.hp[z]), int(player.body.zone_max(z))], i)
		_zone_pop.set_item_metadata(i, z)
	_zone_pop.popup_centered()


func _on_zone_picked(id: int) -> void:
	var zone := String(_zone_pop.get_item_metadata(id))
	var it := _zone_item
	_zone_item = {}
	_use_med(it, zone)


## Quick-use keys: the nth med in rig then pockets.
func _quick_med(n: int) -> void:
	var meds := []
	for loc in ["rig_g", "pockets"]:
		for it in weapons.inv.grid_items(loc):
			if ItemDefs.def_of(it).get("kind") == "med":
				meds.append(it)
	if n < meds.size():
		_use_med(meds[n], "")
	else:
		weapons.message.emit("No med in quick slot %d" % (n + 1))


## Health panel: zone HP, wound icons, build-up meters.
static func _bar(full: int, total: int) -> String:
	var s := ""
	for i in total:
		s += "▓" if i < full else "░"
	return s


func _health_text() -> String:
	var b := player.body
	var s := player.status
	var out := ["== HEALTH =="]
	for z in BodyHealth.ZONES:
		var bar := int(10.0 * float(b.hp[z]) / b.zone_max(z))
		var icons := ""
		for bl in b.bleeds:
			if bl["zone"] == z:
				icons += " BLEED" if float(bl["rate"]) < TacticalConfig.HEAVY_BLEED_DPS else " H.BLEED"
		if b.fractured.has(z):
			icons += " FRACTURE"
		if float(b.hp[z]) <= 0.0:
			icons += " BLACKED"
		out.append("%-7s %s %3d/%-3d%s" % [z.to_upper(), _bar(bar, 10),
			int(b.hp[z]), int(b.zone_max(z)), icons])
	out.append("== STATUS ==")
	var names := {"pain": "PAIN", "radiation": "RAD", "toxication": "TOX", "dehydration": "DEHYDR",
		"energy": "ENERGY", "fatigue": "FATIGUE", "contusion": "CONCUSS"}
	for k in StatusEffects.METERS:
		var v: float = s.m[k]
		if v > 0.01:
			var bar := int(5.0 * v)
			out.append("%-7s %s%s" % [names[k], _bar(bar, 5), " !" if v >= 0.5 else ""])
	if s.pain_off_t > 0.0:
		out.append("ANALGESIA %ds" % int(s.pain_off_t))
	if s.regen_t > 0.0:
		out.append("REGEN %ds" % int(s.regen_t))
	if s.stam_buff_t > 0.0:
		out.append("STIM %ds" % int(s.stam_buff_t))
	if s.iodine_t > 0.0:
		out.append("IODINE %ds" % int(s.iodine_t))
	if not player.med_use.is_empty():
		out.append("USING... %.1fs" % float(player.med_use.get("t", 0.0)))
	return "\n".join(out)


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
	if ItemDefs.def_of(it)["kind"] == "attach":
		var host := view.item_at(view.get_local_mouse_position())
		if not host.is_empty() and host.has("gun"):
			_fit(it, host)
			_settle()
			return
	if target.is_empty():
		_to_world(it)
	elif inv.is_slot(target["loc"]):
		_into_slot(it, target, origin)
	else:
		_into_grid(it, target)
	if it["loc"] == "" and not it.has("world") and ItemDefs.def_of(it)["kind"] == "attach":  # a part pulled off a gun that found no place
		if not inv.add(it):
			world.drop_front(it)
	_settle()


## Part dropped on a gun: fit it (a replaced part goes back to the inventory).
func _fit(att: Dictionary, host: Dictionary) -> void:
	var inv := weapons.inv
	var r := inv.request_fit(host, att)
	if not r["ok"]:
		weapons.message.emit(r["why"])
		if att["loc"] == "":
			inv.add(att)
		return
	if att.has("world"):
		world.release(att)
	if not r["old"].is_empty() and not inv.add(r["old"]):
		world.drop_front(r["old"])
	weapons.message.emit("Fitted %s" % ItemDefs.def_of(att)["name"])


func _on_unfit(gun_item: Dictionary, slot: String, drag: bool) -> void:
	var r := weapons.inv.request_unfit(gun_item, slot)
	if r.is_empty():
		return
	for it in r["spill"]:
		if not weapons.inv.add(it):
			world.drop_front(it)
	if drag:
		view.drag = r["item"]
		view.drag_rot = 0
		view.origin = {}
		view.grab = Vector2(InventoryView.C, InventoryView.C) * 0.5
	elif not weapons.inv.add(r["item"]):
		world.drop_front(r["item"])
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
