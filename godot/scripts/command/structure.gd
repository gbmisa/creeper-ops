class_name Structure
extends RefCounted
## One placed structure. Plain state; StructureManager and the systems it calls own the rules.

static var _next_id := 1

var id: int
var type: String
var def: Dictionary
var x: int                  # cell (footprint centre)
var z: int
var pos: Vector3            # ground point under the centre (or current air position in flight)
var node: Node3D            # root (unscaled): holds body + bars
var body: Node3D            # visual, scaled while under construction
var hp: float
var built := 0.0            # 0..1
var delivered := 0          # build packets arrived
var in_flight := 0          # packets en route to it
var req_acc := 0.0          # packet request accumulator (CW3 request rate)
var connected := false
var cooldown := 0.0
var firing := 0.0           # seconds since a weapon last fired, counting down (ammo headroom)
var charge := 0.0
var ammo := 0.0
var queue: Array = []       # barracks training queue: { type, cost, delivered, train }
var rally: Variant = null   # barracks rally point (Vector3)
var job := {}               # Terp step, plain saveable data: { x, z, paid, timer }
var dead := false
var wet := 0.0
var hurt := 0.0
var warned := false
var supply_on := true       # CW3 toggle: stop requesting ammo
var hold_fire := false      # CW3 toggle: don't shoot (save ammo)
var flight: Variant = null  # Dictionary while lifting/flying/settling (mover.gd)
var hp_bar: Bar
var ammo_bar: Bar
var prey: Dictionary        # what nest raiders see: { pos, radius, alive, hit }


func _init(t: String, cx: int, cz: int) -> void:
	id = _next_id
	_next_id += 1
	type = t
	def = StructureDefs.DEFS[t]
	x = cx
	z = cz
	hp = def.hp


func is_built() -> bool:
	return built >= 1.0


func is_flying() -> bool:
	return flight != null


func has_ammo_store() -> bool:
	return def.has("ammo")


func ammo_max() -> float:
	return def.ammo.max if def.has("ammo") else 0.0


func per_shot() -> float:
	return def.ammo.get("per_shot", 1.0) if def.has("ammo") else 1.0


## Height above `pos` where network lines and packets meet this structure.
func link_point() -> Vector3:
	return pos + Vector3(0, def.link_y, 0)
