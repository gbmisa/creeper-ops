class_name EnemyMortarHit
## Where an enemy mortar shell lands (§4.3). Damage falls off to the edge of the blast.
## Earth drops one level on the 3×3, never below the level as built. Spire is left alone.
## Metal and plated chipping is not in this pass.


static func detonate(host, at: Vector3) -> void:
	var blast := Config.MORTAR_BLAST * Config.CELL
	for q in host.prey.call():
		var prey: Dictionary = q
		if not prey.alive.call():
			continue
		var node := prey.node as Node3D
		var dist := Vector2(node.position.x - at.x, node.position.z - at.z).length()
		if dist > blast:
			continue
		var fall := 1.0 - dist / blast
		var kind := str(prey.get("kind", ""))
		var dmg := Config.MORTAR_STRUCT * fall
		if kind == "operative":
			dmg = Config.SUIT_MAX * Config.MORTAR_OPERATIVE * fall
		elif kind == "unit":
			dmg = Config.MORTAR_UNIT * fall
		prey.hit.call(dmg)
	_earth(host.world, at)
	host.world.effects.burst(at + Vector3.UP, Color("ff4428"), 4.0, 0.45)
	Sfx.play("boom", at)


static func _earth(world: World, at: Vector3) -> void:
	var g := world.grid
	var c := g.world_to_cell(at.x, at.z)
	var edits: Array = []
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var x: int = c.x + dx
			var z: int = c.y + dz
			if not g.in_bounds(x, z):
				continue
			var i := g.idx(x, z)
			if g.material[i] == Grid.Mat.SPIRE:
				continue
			var floor_h := g.base_height[i]
			var h := g.height[i]
			var next := maxf(floor_h, h - 1.0)
			if next < h - 0.001:
				edits.append({ "x": x, "z": z, "height": next })
	if not edits.is_empty():
		TerrainEdit.apply(world, edits)
