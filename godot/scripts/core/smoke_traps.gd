class_name SmokeTraps
## No Operative traps: every surface cell the Operative can stand on must lead back to the
## landing site on foot (walk up CLIMB, jump up to JUMP reach, drop any height). A cell that
## can't is a pit you could fall, pad or pod into and never leave.


static func run(g) -> void:
	var grid: Grid = g.surface.grid
	var reach := Config.CLIMB + Config.JUMP_V * Config.JUMP_V / (2.0 * Config.GRAVITY) / Config.LEVEL_H
	var home: Vector2i = g.level.landing_hint
	# Reverse flood: b is safe if a step from b reaches a safe a.
	var safe := { home: true }
	var open := [home]
	while not open.is_empty():
		var a: Vector2i = open.pop_back()
		for d in RaiderField.DIRS:
			var b: Vector2i = a + d
			if not safe.has(b) and grid.in_bounds(b.x, b.y) and grid.step_ok(b.x, b.y, a.x, a.y, reach, 99.0, Grid.Faction.PLAYER):
				safe[b] = true
				open.append(b)
	var traps: Array[Vector2i] = []
	for z in grid.h:
		for x in grid.w:
			if not safe.has(Vector2i(x, z)):
				traps.append(Vector2i(x, z))
	print("[traps] %d cells: %s" % [traps.size(), str(traps.slice(0, 60))])
	SmokeTest._check("map: no Operative traps", traps.is_empty(), "(%d cells, first %s)" % [traps.size(), str(traps.slice(0, 8))])
	_inside_corner(grid)


## Lands the Operative with its edge sunk into both walls of an inside corner (what a jump
## pad flight could do) and checks it is pushed clear.
static func _inside_corner(grid: Grid) -> void:
	for z in range(1, grid.h - 1):
		for x in range(1, grid.w - 1):
			var h := grid.height_at(x, z)
			if grid.height_at(x + 1, z) - h < 3 or grid.height_at(x, z + 1) - h < 3:
				continue
			var cam := Camera3D.new()
			var pc := PlayerController.new(cam)
			pc.spawn(grid, x, z)
			pc.pos.x = (x + 1) * Config.CELL - 0.1
			pc.pos.z = (z + 1) * Config.CELL - 0.1
			pc._push_out(grid)
			SmokeTest._check("operative: pushed out of an inside corner", pc.can_occupy(grid, pc.pos.x, pc.pos.z),
				"(cell %d,%d pos %.2f,%.2f)" % [x, z, pc.pos.x, pc.pos.z])
			cam.free()
			return
	SmokeTest._check("operative: inside corner found for the push-out test", false)
