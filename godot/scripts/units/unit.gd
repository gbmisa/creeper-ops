class_name Unit
extends RefCounted
## One barracks unit. State machine (see unit_supply.gd):
##   "idle"     standing at its post, fighting what comes in range
##   "move"     walking an order path
##   "resupply" walking home (dry or hurt); docks within range of a barracks to restock
##   "return"   restocked, walking back to the post it left

var type: String
var def: Dictionary
var node: Node3D
var ring: MeshInstance3D
var hp_bar: Bar
var ammo_bar: Bar
var hp: float
var ammo: float
var alive := true
var path: Array[Vector2] = []
var heading := 0.0
var gun_cd := 0.0
var clear_cd := 0.0
var hurt := 0.0
var state := "idle"
var post: Variant = null        # Vector2 world xz the player sent it to
var home: Structure = null      # the barracks that trained it (population cap)
var depot: Structure = null     # the barracks it is walking to for resupply (nearest stocked)
var warned_dry := false
var prey: Dictionary            # what enemies see: { node, radius, alive, hit }


func _init(t: String) -> void:
	type = t
	def = UnitDefs.DEFS[t]
	hp = def.hp
	ammo = def.ammo


var pos: Vector3:
	get: return node.position
	set(v): node.position = v
