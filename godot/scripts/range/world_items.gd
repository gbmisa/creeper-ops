class_name WorldItems
extends Node3D
## Items lying in the range: spawning drops, listing what is within reach, and picking up (F on the one you look at).
## Pure bookkeeping lives here; the inventory screen and PlayerWeapons call take() / drop().

const REACH := 2.5
const NEAR := 2.0  # the inventory screen's ground grid
const LOOK_R := 0.45

var items: Array = []  # item dicts that have a WorldItem
var weapons: PlayerWeapons
var player: TacticalPlayer


func setup(p: TacticalPlayer, w: PlayerWeapons) -> void:
	player = p
	weapons = w
	w.item_dropped.connect(func(it): drop_front(it))


## Spawns an item at a position with a push.
func drop(it: Dictionary, pos: Vector3, vel: Vector3 = Vector3.ZERO) -> WorldItem:
	var wi := WorldItem.new().setup(it)
	add_child(wi)
	wi.global_position = pos
	wi.linear_velocity = vel
	items.append(it)
	return wi


## In front of the player, tossed forward.
func drop_front(it: Dictionary) -> WorldItem:
	var fwd := -player.cam.global_basis.z
	return drop(it, player.eye_pos() + fwd * 0.7 - Vector3(0, 0.3, 0), fwd * 2.0)


## The item no longer lies in the world (picked up or moved into the inventory).
func release(it: Dictionary) -> void:
	items.erase(it)
	var wi = it.get("world")
	it.erase("world")
	if wi != null and is_instance_valid(wi):
		wi.queue_free()


func nearby(pos: Vector3, radius: float = NEAR) -> Array:
	return items.filter(func(it): return (it["world"] as Node3D).global_position.distance_to(pos) <= radius)


## The item closest to the view ray within reach, or {}.
func pick(eye: Vector3, forward: Vector3) -> Dictionary:
	var best := {}
	var best_d := LOOK_R
	for it in items:
		var p: Vector3 = (it["world"] as Node3D).global_position
		if p.distance_to(eye) > REACH or (p - eye).dot(forward) <= 0.0:
			continue
		var d := (p - eye).cross(forward).length()
		if d < best_d:
			best_d = d
			best = it
	return best


## Moves a world item into the inventory (first fit). False when it does not fit.
func take(it: Dictionary, inv: Inventory) -> bool:
	if it["loc"] == "ground":
		inv.remove(it)
	if not inv.add(it):
		return false
	release(it)
	return true


func _process(_dt: float) -> void:
	if weapons == null or weapons.ui_open or weapons.prompt != "":
		return
	var it := pick(player.eye_pos(), -player.cam.global_basis.z)
	if it.is_empty():
		return
	weapons.prompt = "%s: take %s" % [Keybinds.short("t_use"), ItemDefs.label(it)]
	if player.enabled and player.input.act("t_use"):
		if take(it, weapons.inv):
			weapons.message.emit("Took %s" % ItemDefs.label(it))
		else:
			weapons.message.emit("No room for %s" % ItemDefs.label(it))
