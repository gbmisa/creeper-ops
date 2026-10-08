class_name Deposits
extends RefCounted
## Finite ore veins (design §2). A Miner on the cell ships the ore home as return packets.
## Salvage veins are Stage 9b. Level rows are { x, z, left? }.


var world: World
var list: Array[Dictionary] = []
var _at := {}
var _root: Node3D


func setup(w: World, rows: Array) -> void:
	world = w
	_root = Node3D.new()
	_root.name = "OreDeposits"
	w.add_child(_root)
	for raw in rows:
		add(int(raw.x), int(raw.z), float(raw.get("left", Config.ORE_DEPOSIT)))


func add(x: int, z: int, left: float = -1.0) -> Dictionary:
	var g := world.grid
	if not g.in_bounds(x, z):
		return {}
	var i := g.idx(x, z)
	if _at.has(i):
		return _at[i]
	var n := Config.ORE_DEPOSIT if left < 0.0 else left
	var row := { "id": "ore_%d_%d" % [x, z], "x": x, "z": z, "kind": "ore", "left": n, "max": n }
	list.append(row)
	_at[i] = row
	_crystal(row)
	_watch(row)
	return row


func ore_at(x: int, z: int) -> Dictionary:
	if world == null or not world.grid.in_bounds(x, z):
		return {}
	var row = _at.get(world.grid.idx(x, z))
	return row if row != null else {}


func touch(row: Dictionary) -> void:
	var mesh := row.get("mesh") as Node3D
	if mesh == null:
		return
	var share := clampf(float(row.left) / maxf(1.0, float(row.max)), 0.0, 1.0)
	mesh.visible = share > 0.0
	mesh.scale = Vector3.ONE * (0.35 + 0.65 * share)


func _crystal(row: Dictionary) -> void:
	var node := Node3D.new()
	node.position = world.grid.cell_ground(int(row.x), int(row.z))
	_root.add_child(node)
	StructureMeshes.crystal(node, 0.28, 0.9, StructureMeshes.glow(Color("e0a24a"), 1.4), Vector3(0, 0.55, 0))
	StructureMeshes.crystal(node, 0.14, 0.4, StructureMeshes.pal("bronze"), Vector3(0.22, 0.25, 0.08))
	row["mesh"] = node


func _watch(row: Dictionary) -> void:
	var pos: Vector3 = (row.mesh as Node3D).position + Vector3(0, 1.6, 0)
	world.markers.append({ "pos": pos, "color": Color("e0a24a"), "minor": true,
		"label": func(): return "Ore %d" % int(row.left),
		"visible": func(): return float(row.left) > 0.0 })
