class_name Unit
extends RefCounted
## One barracks unit. State machine (see unit_supply.gd):
##   "idle"     standing at its post, fighting what comes in range
##   "move"     walking an order path
##   "resupply" walking home (dry or hurt); docks within range of a barracks to restock
##   "return"   restocked, walking back to the post it left
##   "attack"   hunting `target` until it dies (player order or retaliation), see UnitAttack
##   "patrol"   looping through `patrol` points forever (UnitPatrol), fighting what comes in range

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
var engaged := false       # attack-move: a target is in gun range while walking; path paused
var post: Variant = null        # Vector2 world xz the player sent it to
var home: Structure = null      # the barracks that trained it (population cap)
var depot: Structure = null     # the barracks it is walking to for resupply (nearest stocked)
var patrol: Array[Vector2] = []  # loop of world xz points ("patrol" state); empty = none
var patrol_i := 0               # index of the point it is walking to
var patrol_laps := 0
var patrol_wait := 0.0          # retry delay when the next point is unreachable
var stuck_t := 0.0              # UnitMotion: seconds since the last progress check
var stuck_from := Vector3.ZERO
var warned_dry := false
var grade := "std"             # ammo grade of the rounds in grade_ammo (from its barracks)
var grade_ammo := 0.0
var forced := false             # player move order in progress: no engaging, no firing until it arrives
var target: Dictionary = {}     # "attack" state: the enemy dict being hunted (UnitAttack)
var target_leash := false       # true = retaliation (gives up past RETALIATE_LEASH of leash_from)
var leash_from := Vector2.ZERO
var wait := false               # path request queued (UnitPaths); stands still until served
var attack_t := 0.0             # re-path timer
var prey: Dictionary            # what enemies see: { node, radius, alive, hit }


func _init(t: String) -> void:
	type = t
	def = UnitDefs.DEFS[t]
	hp = def.hp
	ammo = def.ammo


var pos: Vector3:
	get: return node.position
	set(v): node.position = v
