class_name GunsmithUI
extends CanvasLayer
## F141: the gunsmith screen opened at the workbench. Guns left, live 3D preview middle, slots + spare parts right.
## Fitting / removing goes through the same Inventory requests and InventoryUI helpers as the inventory drag.
## The player is frozen while it is open; Esc / Tab / F close it.

var weapons: PlayerWeapons
var player: TacticalPlayer
var inv_ui: InventoryUI
var is_open := false
var view := GunsmithView.new()
var info_toggle := Callable()  # set by the workbench: shows / hides the F115 reference panel


func setup(w: PlayerWeapons, p: TacticalPlayer, u: InventoryUI) -> void:
	weapons = w
	player = p
	inv_ui = u
	layer = 9
	visible = false
	view.ui = self
	add_child(view)
	var b := UiKit.button("Gun info", func(): if info_toggle.is_valid(): info_toggle.call())
	b.position = Vector2(200, 24)
	view.add_child(b)


func _process(_dt: float) -> void:
	if is_open and player.input.frame.act("inventory"):
		close()


func open() -> void:
	is_open = true
	visible = true
	weapons.ui_open = true
	player.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	view.refresh()


func close() -> void:
	is_open = false
	visible = false
	view.cancel_drag()
	weapons.ui_open = false
	player.enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Every gun the player has (equipped slots, then bags and pockets), as inventory items.
func guns() -> Array:
	var out := []
	for s in ["primary", "secondary", "holster"]:
		var it = weapons.inv.equipped(s)
		if it != null and it.has("gun"):
			out.append(it)
	for loc in Inventory.GRIDS + ["pockets"]:
		for it in weapons.inv.grid_items(loc):
			if it.has("gun") and not out.has(it):
				out.append(it)
	return out


## Spare attachment items in the bags and pockets.
func spares() -> Array:
	var out := []
	for loc in Inventory.GRIDS + ["pockets"]:
		for it in weapons.inv.grid_items(loc):
			if ItemDefs.def_of(it)["kind"] == "attach" and not out.has(it):
				out.append(it)
	return out


func fit(att: Dictionary, gun_item: Dictionary) -> void:
	inv_ui._fit(att, gun_item)
	inv_ui._settle()


## Takes the part in `slot` off the gun; the part comes back as a loose item (loc "") for the caller to place.
func unfit(gun_item: Dictionary, slot: String) -> Dictionary:
	var r := weapons.inv.request_unfit(gun_item, slot)
	if r.is_empty():
		return {}
	for it in r["spill"]:
		if not weapons.inv.request_add(it)["ok"]:
			inv_ui.world.drop_front(it)
	weapons.sync()
	return r["item"]


## A loose part (loc "") goes back in the bags, else onto the ground.
func stash(it: Dictionary) -> void:
	if it["loc"] == "" and not weapons.inv.request_add(it)["ok"]:
		inv_ui.world.drop_front(it)
	inv_ui._settle()
